import Foundation
import Codability
import Vapor
import Fluent
import SQLKit

public class QueryParameterFilter {
    public var schema: Schema.Type
    public var name: String
    public var method: QueryParameterFilter.Method
    public var value: Value<String>
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
    
    func encodableValue(for rangeValue: QueryParameterRangeValue) throws -> [Encodable] {
//        func isNull(value: String) -> Bool {
//            return ["null", ""].contains(value)
//        }
//        let lowerBound = isNull(value: rangeValue.lowerBound) ? AnyCodable(nilLiteral: ()) : try encodableValue(for: rangeValue.lowerBound)
//        let upperBound = isNull(value: rangeValue.upperBound) ? AnyCodable(nilLiteral: ()) : try encodableValue(for: rangeValue.upperBound)
        
        let lowerBound = rangeValue.lowerBound//try encodableValue(for: rangeValue.lowerBound)
        let upperBound = rangeValue.upperBound//try encodableValue(for: rangeValue.upperBound)
        return [lowerBound, upperBound]
    }
    
    public enum Value<S: Comparable> {
        case single(S)
        case multiple([S])
        case range(QueryParameterRangeValue)
    }
    
    public enum Method: String, Codable, CaseIterable {
        public enum Aliases: String, Codable, CaseIterable {
            //Shorthand Aliases
            case eq = "eq"       // equals
            case neq = "neq"     // notEquals
            case nin = "nin"     // arrNotIncludes
            case gt = "gt"       // greaterThan
            case gte = "gte"     // greaterThanOrEqualTo
            case lt = "lt"       // lessThan
            case lte = "lte"     // lessThanOrEqualTo
            case sw = "sw"       // startsWith
            case nsw = "nsw"     // notStartsWith
            case ew = "ew"       // endsWith
            case new = "new"     // notEndsWith
            case ct = "ct"       // contains
            case nct = "nct"     // notContains
            case ca = "ca"       // arrIncludesAll
            case cb = "cb"       // arrIsContainedBy
            case cany = "cany"   // arrIncludesSome
            case `in` = "in"     // arrIncludes
            case notIn = "notIn" // arrNotIncludes
            case bt = "bt"       // between
            case bti = "bti"     // betweenInclusive
            case fz = "fz"       // fuzzy
            case emp = "emp"     // empty
            case nemp = "nemp"   // notEmpty
            case nul = "nul"     // isNull
            case nnul = "nnul"   // isNotNull
            case rng = "rng"     // inNumberRange
            case st = "st"       // searchText
            case wk = "wk"       // weakEquals
            case es = "es"       // equalsString
            case ess = "ess"     // equalsStringSensitive
            case inc = "inc"     // includesString
            case incs = "incs"   // includesStringSensitive
            
            public func toMethod() -> Method {
                switch self {
                case .eq: return .equals
                case .neq: return .notEquals
                case .nin: return .arrNotIncludes
                case .gt: return .greaterThan
                case .gte: return .greaterThanOrEqualTo
                case .lt: return .lessThan
                case .lte: return .lessThanOrEqualTo
                case .sw: return .startsWith
                case .nsw: return .notStartsWith
                case .ew: return .endsWith
                case .new: return .notEndsWith
                case .ct: return .contains
                case .nct: return .arrNotIncludes
                case .ca: return .arrIncludesAll
                case .cb: return .arrIsContainedBy
                case .cany: return .arrIncludesSome
                case .in: return .arrIncludes
                case .notIn: return .arrNotIncludes
                case .bt: return .between
                case .bti: return .betweenInclusive
                case .fz: return .fuzzy
                case .emp: return .empty
                case .nemp: return .notEmpty
                case .nul: return .isNull
                case .nnul: return .isNotNull
                case .rng: return .inNumberRange
                case .st: return .searchText
                case .wk: return .weakEquals
                case .es: return .equalsString
                case .ess: return .equalsStringSensitive
                case .inc: return .includesString
                case .incs: return .includesStringSensitive
                }
            }
        }
        
        // Material React Table (MRT) Filters
        case between = "between" // Value falls between two bounds (exclusive), with numeric handling
        case betweenInclusive = "betweenInclusive" // Value falls between two bounds (inclusive), with numeric handling
        case contains = "contains" // String contains the filter text (case-insensitive)
        case empty = "empty" // Value is empty or only whitespace
        case endsWith = "endsWith" // String ends with filter text (case-insensitive)
        case fuzzy = "fuzzy" // Fuzzy matching using match-sorter ranking algorithm
        case greaterThan = "greaterThan" // Value exceeds filter (numbers and strings)
        case greaterThanOrEqualTo = "greaterThanOrEqualTo" // Value equals or exceeds filter (numbers and strings)
        case lessThan = "lessThan" // Value is below filter (numbers and strings)
        case lessThanOrEqualTo = "lessThanOrEqualTo" // Value equals or is below filter (numbers and strings)
        case notEmpty = "notEmpty" // Value contains non-whitespace characters
        case notEquals = "notEquals" // Value differs from filter text (case-insensitive)
        case startsWith = "startsWith" // String begins with filter text (case-insensitive)
        
        // TanStack Table Filters
        case arrIncludes = "arrIncludes" //Item inclusion within an array
        case arrIncludesAll = "arrIncludesAll" //All items included in an array
        case arrIncludesSome = "arrIncludesSome" //Some items included in an array
        case equals = "equals" //Object/referential equality Object.is/===
        case equalsString = "equalsString" //Case-sensitive string equality
        case equalsStringSensitive = "equalsStringSensitive" //Case-insensitive string equality
        case includesString = "includesString" //Case-insensitive string inclusion
        case includesStringSensitive = "includesStringSensitive" //Case-sensitive string inclusion
        case inNumberRange = "inNumberRange"//Number range inclusion
        case weakEquals = "weakEquals"//Weak object/referential equality ==
        
        // Custom Filters
        case filter = "filter"
        case searchText = "searchText"
        case notStartsWith = "notStartsWith"
        case notEndsWith = "notEndsWith"
        case arrIsContainedBy = "arrIsContainedBy"
        case arrNotIncludes = "arrNotIncludes"
        case isNull = "isNull"       // Value is null
        case isNotNull = "isNotNull" // Value is not null
        
        // Convert to database query filter method
        public func toDatabaseQueryFilterMethod() -> DatabaseQuery.Filter.Method {
            switch self {
            case .equals, .equalsString, .equalsStringSensitive, .weakEquals:
                return .equal
            case .notEquals:
                return .notEqual
            case .arrIncludes:
                return .inSubSet
            case .arrIncludesAll:
                return .containsArray
            case .arrIncludesSome:
                return .overlaps
            case .arrIsContainedBy:
                return .isContainedByArray
            case .greaterThan:
                return .greaterThan
            case .greaterThanOrEqualTo:
                return .greaterThanOrEqual
            case .lessThan:
                return .lessThan
            case .lessThanOrEqualTo:
                return .lessThanOrEqual
            case .startsWith:
                return .contains(inverse: false, .prefix)
            case .notStartsWith:
                return .contains(inverse: true, .prefix)
            case .endsWith:
                return .contains(inverse: false, .suffix)
            case .notEndsWith:
                return .contains(inverse: true, .suffix)
            case .contains, .includesString, .includesStringSensitive:
                return .contains(inverse: false, .anywhere)
            case .empty:
                return .placeholder
            case .notEmpty:
                return .placeholder
            case .fuzzy:
                return .similarTo
            case .between, .betweenInclusive, .inNumberRange:
                return .placeholder
            case .searchText:
                return .fullTextSearch
            case .filter:
                return .equal
            case .arrNotIncludes:
                return .notInSubSet
            case .isNull:
                return .placeholder
            case .isNotNull:
                return .placeholder
            }
        }
    }

    
    public func queryField(for schema: Schema.Type? = nil) -> DatabaseQuery.Field {
        let schema = schema ?? self.schema
        return .path([FieldKey(name)], schema: schema.schemaOrAlias)
    }
    
    internal init(schema: Schema.Type,
                  name: String,
                  method: QueryParameterFilter.Method,
                  value: QueryParameterFilter.Value<String>,
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
        
        guard case let .`where`(field, method, value) = filterCondition else {
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
        
        self.init(schema: schema,
                  name: field,
                  method: method,
                  value: .single(value.description),
                  queryValueType: type(of: value.value))
    }
    
    
}


public enum FilterCondition: Codable {
    case `where`(field: String, method: QueryParameterFilter.Method, value: AnyCodable)
    case and([FilterCondition])
    case or([FilterCondition])
    
    private enum CodingKeys: String, CodingKey {
        case field, method, value
        case and, or
    }
    
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let field = try? container.decode(String.self, forKey: .field),
           let method = (try? container.decode(QueryParameterFilter.Method.self, forKey: .method)) ??
            (try? container.decode(QueryParameterFilter.Method.Aliases.self, forKey: .method).toMethod()),
           let value = try? container.decode(AnyCodable.self, forKey: .value) {
            self = .`where`(field: field, method: method, value: value)
        } else if let andConditions = try? container.decode([FilterCondition].self, forKey: .and) {
            self = .and(andConditions)
        } else if let orConditions = try? container.decode([FilterCondition].self, forKey: .or) {
            self = .or(orConditions)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid filter condition"))
        }
    }
    
    public static func decoded(from filterString: String) throws -> FilterCondition {
        return try JSONDecoder().decode(FilterCondition.self, from: Data(filterString.utf8))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .`where`(let field, let method, let value):
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


public extension DatabaseQuery.Filter {
    
    static func build<M: Model>(from filterString: String,
                                builder: QueryParameterFilter.Builder<M>) throws -> DatabaseQuery.Filter? {
        guard !filterString.isEmpty else {
            return nil
        }
        
        let condition = try FilterCondition.decoded(from: filterString)
        return try build(from: condition, builder: builder)
    }
    
    
    static func build<M>(from condition: FilterCondition,
                         builder: QueryParameterFilter.Builder<M>) throws -> DatabaseQuery.Filter? {
        let fieldFilterOverrides = builder.config.fieldOverrides
        let nestedFilterBuilders = builder.config.nestedBuilders
        let schema = builder.schema
        
        switch condition {
        case let .`where`(field, method, value):
            if let override = fieldFilterOverrides[field] {
                return try override(builder.query, method, value)
            }
            let fieldKey = builder.config.fieldKeyMap[field] ?? FieldKey(field)
            let path = [fieldKey]
            
            if case .filter = method,
               let nestedFilterString = (value.value as? String)?.urlDecoded,
               let nestedBuilder = nestedFilterBuilders[field] {
                let nestedCondition = try FilterCondition.decoded(from: nestedFilterString)
                return try? nestedBuilder(builder.query, field, nestedCondition)
            }
            
            return try buildSimpleFilter(field: .path([FieldKey(field)], schema: schema),
                                        method: method,
                                        value: value)
            
        case let .and(conditions):
            let filters = try conditions.compactMap { try build(from: $0, builder: builder) }
            return .group(filters, .and)
        case let .or(conditions):
            let filters = try conditions.compactMap { try build(from: $0, builder: builder) }
            return .group(filters, .or)
        }
    }
    
    static func buildSimpleFilter(field: DatabaseQuery.Field,
                                  method: QueryParameterFilter.Method,
                                  value: AnyCodable) throws -> DatabaseQuery.Filter? {
        switch method {
        case .between, .betweenInclusive, .inNumberRange:
            guard let range = value.value as? [Any], range.count == 2 else {
                throw QueryParameterFilterError.invalidFilterConfiguration
            }
            let lower = range[0]
            let upper = range[1]
            
            func isNull(value: Any) -> Bool {
                return ["null", ""].any { val in
                    return val == "\(value)"
                }
            }
            
            let hasLower = !isNull(value: lower)
            let hasUpper = !isNull(value: upper)
            
            if !hasLower && !hasUpper {
                return nil
            }
            
            var filters: [DatabaseQuery.Filter] = []
            
            if hasLower {
                let lowerFilter = DatabaseQuery.Filter.value(field,
                                                         method == .betweenInclusive ? .greaterThanOrEqual : .greaterThan,
                                                         .bind(AnyCodable(lower)))
                filters.append(lowerFilter)
            }
            
            if hasUpper {
                let upperFilter = DatabaseQuery.Filter.value(field,
                                                         method == .betweenInclusive ? .lessThanOrEqual : .lessThan,
                                                         .bind(AnyCodable(upper)))
                filters.append(upperFilter)
            }
            
            return filters.count > 1 ? .group(filters, .and) : filters.first

        case .isNull:
            return .value(field, .equal, .null)
        case .isNotNull:
            return .value(field, .notEqual, .null)
        case .empty:
            return .value(field, .equal, .bind(""))
            
        case .notEmpty:
            return .value(field, .notEqual, .bind(""))
            
        case .fuzzy:
            return .value(field, .similarTo, value.toDatabaseQueryValue())
            
        default:
            return .value(field, method.toDatabaseQueryFilterMethod(), value.toDatabaseQueryValue())
        }
    }

}

public extension QueryBuilder {
    
    func filterWithQueryParameter(at queryParameterKey: String = "filter",
                                  in request: Request,
                                  builder: QueryParameterFilter.Builder<Model>? = nil) throws -> Self {
        guard let filterString: String = request.query[queryParameterKey] else {
            return self
        }
        return try filterWithQueryParameterString(filterString, builder: builder)
    }
    
    func filterWithQueryParameterString(_ queryParameterFilterString: String,
                                        builder: QueryParameterFilter.Builder<Model>? = nil) throws -> Self {
        if let filterCondition = try DatabaseQuery.Filter.build(from: queryParameterFilterString, builder: builder ?? QueryParameterFilter.Builder<Model>(self)) {
            return self.filter(filterCondition)
        }
        return self
    }
}
extension DatabaseQuery.Filter.Method {
    static var placeholder: DatabaseQuery.Filter.Method {
        return .custom("")
    }
}

// PostgreSQL specific extensions
public extension DatabaseQuery.Filter.Method {
    //PSQL only
    static var containsArray: DatabaseQuery.Filter.Method {
        return .custom(SQLRaw("@>"))
    }

    //PSQL only
    static var isContainedByArray: DatabaseQuery.Filter.Method {
        return .custom(SQLRaw("<@"))
    }

    //PSQL only
    static var overlaps: DatabaseQuery.Filter.Method {
        return .custom(SQLRaw("&&"))
    }
    
    //PSQL only
    static var similarTo: DatabaseQuery.Filter.Method {
        return .custom(SQLRaw("SIMILAR TO"))
    }
    
    //PSQL only
    static var fullTextSearch: DatabaseQuery.Filter.Method {
        return .custom(SQLRaw("@@"))
    }
}



public extension AnyCodable {
    func toDatabaseQueryValue() -> DatabaseQuery.Value {
        switch value {
        case let doubleValue as Double:
            return .bind(doubleValue)
        case let intValue as Int:
            return .bind(Int64(intValue))
        case let boolValue as Bool:
            return .bind(boolValue)
        case let stringValue as String:
            return .bind(stringValue)
        case let arrayValue as [Any]:
            return .array(arrayValue.map { AnyCodable($0).toDatabaseQueryValue() })
        default:
            return .bind(description)
        }
    }
}

extension String {
    /// Converts string to boolean value if possible
    /// - Returns: Boolean value if string represents a valid boolean, nil otherwise
    var bool: Bool? {
        switch self.lowercased() {
        case "true", "yes", "1", "y": return true
        case "false", "no", "0", "n": return false
        default: return nil
        }
    }
}
