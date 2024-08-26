import Foundation
import Codability
import Vapor
import Fluent

public class QueryParameterFilter {
    public var schema: Schema.Type
    public var name: String
    public var method: QueryParameterFilter.Method
    public var value: Value<String, [String]>
    public var queryValueType: Any.Type? = nil
    
    func encodableValue(for value: String) throws -> Encodable {
        switch queryValueType {
        case is Bool.Type:
            return try value.bool.unwrapped(or: Abort(.badRequest))
        case is Int.Type:
            return try Int(value).unwrapped(or: Abort(.badRequest))
        case is Double.Type:
            return try Double(value).unwrapped(or: Abort(.badRequest))
        default: return value
        }
    }
    
    func encodableValue(for values: [String]) throws -> [Encodable] {
        return try values.map({try encodableValue(for: $0)})
    }
    
    public enum Value<S, M> {
        case single(S)
        case multiple(M)
    }
    
    public enum Method: String, Codable, CaseIterable {
        case equal = "eq"
        case notEqual = "neq"
        case `in` = "in"
        case notIn = "nin"
        case greaterThan = "gt"
        case greaterThanOrEqual = "gte"
        case lessThan = "lt"
        case lessThanOrEqual = "lte"
        case startsWith = "sw"
        case notStartsWith = "nsw"
        case endsWith = "ew"
        case notEndsWith = "new"
        case contains = "ct"
        case notContains = "nct"
    }
    
    public func queryField(for schema: Schema.Type? = nil) -> DatabaseQuery.Field {
        let schema = schema ?? self.schema
        return .path([FieldKey(name)], schema: schema.schemaOrAlias)
    }
    
    internal init(schema: Schema.Type,
                  name: String,
                  method: QueryParameterFilter.Method,
                  value: QueryParameterFilter.Value<String, [String]>,
                  queryValueType: Any.Type? = nil) {
        self.schema = schema
        self.name = name
        self.method = method
        self.value = value
        self.queryValueType = queryValueType
    }
    
    public convenience init(schema: Schema.Type,
                            from queryContainer: URLQueryContainer) throws {
        guard let filterJson: String = queryContainer["filter"] else {
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
        
        let decoder = JSONDecoder()
        let filterCondition = try decoder.decode(FilterCondition.self, from: Data(filterJson.utf8))
        
        guard case let .comparison(field, method, value) = filterCondition else {
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
        
        self.init(schema: schema,
                  name: field,
                  method: method,
                  value: .single(value.description),
                  queryValueType: type(of: value.value))
    }
    
    public convenience init(schema: Schema.Type,
                            fieldName: String,
                            withQueryValueAt queryParameterKey: String,
                            as queryValueType: Any.Type? = nil,
                            from queryContainer: URLQueryContainer) throws {
        
        let decoder = URLEncodedFormDecoder()
        
        guard let config = queryContainer[String.self, at: queryParameterKey] else {
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
        
        let filterConfig = config.toFilterConfig
        
        let method = filterConfig.method
        let value = filterConfig.value
        
        let multiple = [.in, .notIn].contains(method)
        var filterValue: QueryParameterFilter.Value<String, [String]>
        
        if multiple {
            let str = value.components(separatedBy: ",").map { "\(queryParameterKey)[]=\($0)" }.joined(separator: "&")
            filterValue = try .multiple(decoder.decode(SingleValueDecoder.self, from: str).get(at: [queryParameterKey.codingKey]))
        } else {
            let str = "\(queryParameterKey)=\(value)"
            filterValue = try .single(decoder.decode(SingleValueDecoder.self, from: str).get(at: [queryParameterKey.codingKey]))
        }
        self.init(schema: schema,
                  name: fieldName,
                  method: method,
                  value: filterValue,
                  queryValueType: queryValueType)
    }
}

enum FilterCondition: Codable {
    case comparison(field: String, method: QueryParameterFilter.Method, value: AnyCodable)
    case and([FilterCondition])
    case or([FilterCondition])
    
    private enum CodingKeys: String, CodingKey {
        case field, method, value
        case and, or
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let field = try? container.decode(String.self, forKey: .field),
           let method = try? container.decode(QueryParameterFilter.Method.self, forKey: .method),
           let value = try? container.decode(AnyCodable.self, forKey: .value) {
            self = .comparison(field: field, method: method, value: value)
        } else if let andConditions = try? container.decode([FilterCondition].self, forKey: .and) {
            self = .and(andConditions)
        } else if let orConditions = try? container.decode([FilterCondition].self, forKey: .or) {
            self = .or(orConditions)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid filter condition"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .comparison(let field, let method, let value):
            try container.encode(field, forKey: .field)
            try container.encode(method, forKey: .method)
            try container.encode(value, forKey: .value)
        case .and(let conditions):
            try container.encode(conditions, forKey: .and)
        case .or(let conditions):
            try container.encode(conditions, forKey: .or)
        }
    }
}

extension DatabaseQuery.Filter {
    static func build(from condition: FilterCondition, schema: String) -> DatabaseQuery.Filter {
        switch condition {
        case let .comparison(field, method, value):
            return .value(.path([FieldKey(field)], schema: schema), method.toDatabaseQueryFilterMethod(), value.toDatabaseQueryValue())
        case let .and(conditions):
            let filters = conditions.map { build(from: $0, schema: schema) }
            return .group(filters, .and)
        case let .or(conditions):
            let filters = conditions.map { build(from: $0, schema: schema) }
            return .group(filters, .or)
        }
    }
}

extension QueryParameterFilter.Method {
    func toDatabaseQueryFilterMethod() -> DatabaseQuery.Filter.Method {
        switch self {
        case .equal: return .equal
        case .notEqual: return .notEqual
        case .in: return .inSubSet
        case .notIn: return .notInSubSet
        case .greaterThan: return .greaterThan
        case .greaterThanOrEqual: return .greaterThanOrEqual
        case .lessThan: return .lessThan
        case .lessThanOrEqual: return .lessThanOrEqual
        case .startsWith: return .contains(inverse: false, .prefix)
        case .notStartsWith: return .contains(inverse: true, .prefix)
        case .endsWith: return .contains(inverse: false, .suffix)
        case .notEndsWith: return .contains(inverse: true, .suffix)
        case .contains: return .contains(inverse: false, .anywhere)
        case .notContains: return .contains(inverse: true, .anywhere)
        }
    }
}

extension AnyCodable {
    func toDatabaseQueryValue() -> DatabaseQuery.Value {
        switch value {
        case let stringValue as String:
            return .bind(stringValue)
        case let intValue as Int:
            return .bind(Int64(intValue))
        case let doubleValue as Double:
            return .bind(doubleValue)
        case let boolValue as Bool:
            return .bind(boolValue)
        case let arrayValue as [Any]:
            return .array(arrayValue.map { AnyCodable($0).toDatabaseQueryValue() })
        default:
            return .bind(description)
        }
    }
}

extension Request {
    func advancedFilter<T: Model>(_ schema: T.Type) throws -> DatabaseQuery.Filter {
        guard let filterJson: String = query["filter"] else {
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
        
        let decoder = JSONDecoder()
        let filterCondition = try decoder.decode(FilterCondition.self, from: Data(filterJson.utf8))
        
        return DatabaseQuery.Filter.build(from: filterCondition, schema: T.schema)
    }
}

extension String {
    var bool: Bool? {
        switch self {
        case "true", "yes", "1", "y": return true
        case "false", "no", "0", "n": return false
        default: return nil
        }
    }
}

