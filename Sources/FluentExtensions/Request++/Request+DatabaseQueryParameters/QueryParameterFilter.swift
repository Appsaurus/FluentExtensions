//
//  QueryParameterFilter.swift
//  
//
//  Created by Brian Strobach on 9/29/21.
//

import VaporExtensions
import Codability


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

    public enum Method: String {
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
//
//    func databaseQueryFilter(for schema: String) -> DatabaseQuery.Filter {
//        DatabaseQuery.Filter.value(.path([name.fieldKey], schema: schema), <#T##DatabaseQuery.Filter.Method#>, <#T##DatabaseQuery.Value#>)
//    }

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

#if swift(>=4.2)
extension QueryParameterFilter.Method: CaseIterable {}
#else
public extension QueryParameterFilter.Method {
    static var allCases: [QueryParameterFilter.Method] {
        return [
            .equal,
            .notEqual,
            .in,
            .notIn,
            .greaterThan,
            .greaterThanOrEqual,
            .lessThan,
            .lessThanOrEqual,
            .startsWith,
            .notStartsWith,
            .endsWith,
            .notEndsWith,
            .contains,
            .notContains,
        ]
    }
}
#endif

extension QueryParameterFilter.Value where S == String, M == [String] {
    func to(type: Any.Type) -> AnyCodable {

        switch self {
            case .single(let value):
                var codableValue: AnyCodable? = nil
                if type == Bool.self {
                    codableValue = Bool(value)?.wrapAsAnyCodable()
                }
                else if type ==  Int.self || type == Int?.self {
                    codableValue = Int(value)?.wrapAsAnyCodable()
                }

                else if type == Double.self {
                    codableValue = Double(value)?.wrapAsAnyCodable()
                }

                else if type ==  Float.self {
                    codableValue = Float(value)?.wrapAsAnyCodable()
                }
                return codableValue ?? value.wrapAsAnyCodable()
            case .multiple(let values):
                return values.map({QueryParameterFilter.Value.single($0).to(type: type)}).wrapAsAnyCodable()
        }

    }

    //    func toValues<T>(type: [T].Type) -> [T]? {
    //        if case let .multiple(values) = self {
    //            return values.map({FilterValue.single($0).to(type: T.self)})
    //        }
    //    }
}

fileprivate extension String {
    /// Converts the string to a `Bool` or returns `nil`.
    var bool: Bool? {
        switch self {
        case "true", "yes", "1", "y": return true
        case "false", "no", "0", "n": return false
        default: return nil
        }
    }
}

