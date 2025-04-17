
import Foundation
import Codability
import Vapor
import Fluent
import SQLKit

/// A class that handles filtering of database queries based on query parameters.
///
/// This class provides functionality to create and apply filters to database queries based on URL query parameters.
/// It supports various filtering methods including equality, range comparisons, string operations, and array operations.
public class QueryParameterFilter {
    /// The database schema type to filter on
    public var schema: Schema.Type
    /// The name of the field to filter
    public var name: String
    /// The filtering method to apply
    public var method: QueryParameterFilter.Method
    /// The filter value
    public var value: Value<String>
    /// Optional type information for query value casting
    public var queryValueType: Any.Type? = nil
    
    /// Converts a string value to an appropriate `Encodable` type based on `queryValueType`
    /// - Parameter value: The string value to convert
    /// - Returns: An `Encodable` value of the appropriate type
    /// - Throws: `Abort(.badRequest)` if value cannot be converted to the expected type
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
    
    /// Converts an array of string values to an array of appropriate `Encodable` types
    /// - Parameter values: Array of string values to convert
    /// - Returns: Array of converted `Encodable` values
    func encodableValue(for values: [String]) throws -> [Encodable] {
        return try values.map({try encodableValue(for: $0)})
    }
    
    /// Converts a range value to an array of appropriate `Encodable` types
    /// - Parameter rangeValue: The range value to convert
    /// - Returns: Array containing the lower and upper bounds as `Encodable` values
    func encodableValue(for rangeValue: QueryParameterRangeValue) throws -> [Encodable] {
        let lowerBound = rangeValue.lowerBound
        let upperBound = rangeValue.upperBound
        return [lowerBound, upperBound]
    }
    
    /// Represents different types of filter values that can be applied
    public enum Value<S: Comparable> {
        /// A single value
        case single(S)
        /// Multiple values for IN-type operations
        case multiple([S])
        /// A range of values with upper and lower bounds
        case range(QueryParameterRangeValue)
    }
    
    /// Represents different filtering methods that can be applied
    public enum Method: String, Codable, CaseIterable {
        /// Shorthand aliases for filter methods to improve API usability
        public enum Aliases: String, Codable, CaseIterable {
            case eq = "eq"       // equals
            case neq = "neq"     // notEquals
            case nin = "nin"     // notEqualToAny
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
            case notIn = "notIn" // notEqualToAny
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
            
            /// Converts an alias to its corresponding full method
            public func toMethod() -> Method {
                switch self {
                case .eq: return .equals
                case .neq: return .notEquals
                case .nin: return .notEqualToAny
                case .gt: return .greaterThan
                case .gte: return .greaterThanOrEqualTo
                case .lt: return .lessThan
                case .lte: return .lessThanOrEqualTo
                case .sw: return .startsWith
                case .nsw: return .notStartsWith
                case .ew: return .endsWith
                case .new: return .notEndsWith
                case .ct: return .contains
                case .nct: return .notContains
                case .ca: return .arrIncludesAll
                case .cb: return .arrIsContainedBy
                case .cany: return .arrIncludesSome
                case .in: return .equalsAny
                case .notIn: return .notEqualToAny
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
        
        // MARK: - Material React Table (MRT) Filters
        case between = "between"
        case betweenInclusive = "betweenInclusive"
        case contains = "contains"
        case empty = "empty"
        case endsWith = "endsWith"
        case fuzzy = "fuzzy"
        case greaterThan = "greaterThan"
        case greaterThanOrEqualTo = "greaterThanOrEqualTo"
        case lessThan = "lessThan"
        case lessThanOrEqualTo = "lessThanOrEqualTo"
        case notEmpty = "notEmpty"
        case notEquals = "notEquals"
        case startsWith = "startsWith"
        
        // MARK: - TanStack Table Filters
        case arrIncludes = "arrIncludes"
        case arrIncludesAll = "arrIncludesAll"
        case arrIncludesSome = "arrIncludesSome"
        case equals = "equals"
        case equalsString = "equalsString"
        case equalsStringSensitive = "equalsStringSensitive"
        case includesString = "includesString"
        case includesStringSensitive = "includesStringSensitive"
        case inNumberRange = "inNumberRange"
        case weakEquals = "weakEquals"
        
        // MARK: - Custom Filters
        case filter = "filter"
        case searchText = "searchText"
        case notStartsWith = "notStartsWith"
        case notEndsWith = "notEndsWith"
        case arrIsContainedBy = "arrIsContainedBy"
        case isNull = "isNull"
        case isNotNull = "isNotNull"
        case equalsAny = "equalsAny"
        case notEqualToAny = "notEqualToAny"
        case notContains = "notContains"
        
        /// Converts the filter method to its corresponding database query filter method
        public func toDatabaseQueryFilterMethod() -> DatabaseQuery.Filter.Method {
            switch self {
            case .equals, .equalsString, .equalsStringSensitive, .weakEquals:
                return .equal
            case .notEquals:
                return .notEqual
            case .arrIncludes:
                return .placeholder
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
            case .notContains:
                return .contains(inverse: true, .anywhere)
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
            case .isNull:
                return .placeholder
            case .isNotNull:
                return .placeholder
            case .equalsAny:
                return .placeholder
            case .notEqualToAny:
                return .placeholder
            }
        }
    }
    
    /// Gets the database query field for the filter
    /// - Parameter schema: Optional schema override
    /// - Returns: A `DatabaseQuery.Field` representing the field to filter on
    public func queryField(for schema: Schema.Type? = nil) -> DatabaseQuery.Field {
        let schema = schema ?? self.schema
        return .path([FieldKey(name)], schema: schema.schemaOrAlias)
    }
    
    /// Internal initializer for creating a filter
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
    
    /// Convenience initializer that creates a filter from a URL query container
    /// - Parameters:
    ///   - schema: The database schema type
    ///   - queryContainer: The URL query container containing the filter
    /// - Throws: `QueryParameterFilterError` if filter configuration is invalid
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

/// Represents different types of filter conditions that can be combined
public enum FilterCondition: Codable {
    /// A single filter condition
    case `where`(field: String, method: QueryParameterFilter.Method, value: AnyCodable)
    /// A group of conditions that must all be true (AND)
    case and([FilterCondition])
    /// A group of conditions where at least one must be true (OR)
    case or([FilterCondition])
    
    private enum CodingKeys: String, CodingKey {
        case field, method, value
        case and, or
    }
    
    /// Decodes a filter condition from JSON data
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
    
    /// Decodes a filter condition from a JSON string
    public static func decoded(from filterString: String) throws -> FilterCondition {
        return try JSONDecoder().decode(FilterCondition.self, from: Data(filterString.utf8))
    }
    
    /// Encodes the filter condition to JSON
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

/// Extension to support building database query filters
public extension DatabaseQuery.Filter {
    
    /// Builds a database query filter from a filter string
    /// - Parameters:
    ///   - filterString: The JSON filter string
    ///   - builder: The query parameter filter builder
    /// - Returns: A database query filter if valid, nil otherwise
    static func build<M: Model>(from filterString: String,
                                builder: QueryParameterFilter.Builder<M>) throws -> DatabaseQuery.Filter? {
        guard !filterString.isEmpty else {
            return nil
        }
        
        let condition = try FilterCondition.decoded(from: filterString)
        return try build(from: condition, builder: builder)
    }
    
    /// Builds a database query filter from a filter condition
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
            
            if case .filter = method,
               let nestedFilterString = (value.value as? String)?.urlDecoded,
               let nestedBuilder = nestedFilterBuilders[field] {
                let nestedCondition = try FilterCondition.decoded(from: nestedFilterString)
                return try? nestedBuilder(builder.query, field, nestedCondition)
            }
            
            let fieldKey = builder.config.fieldKeyMap[field] ?? FieldKey(field)
            return try buildSimpleFilter(field: .path([fieldKey], schema: schema),
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
    
    /// Builds a simple database query filter
    static func buildSimpleFilter(field: DatabaseQuery.Field,
                                  method: QueryParameterFilter.Method,
                                  value: AnyCodable) throws -> DatabaseQuery.Filter? {
        // Helper functions
        func isNull(value: Any) -> Bool {
            if type(of: value) == type(of: ()) {
                return true
            }
            return ["null", "", "<null>"].contains("\(value)")
        }
        
        func parseNumberRangeBoundary(_ value: Any) -> Double? {
            if let num = value as? Double {
                return num
            } else if let num = value as? Int {
                return Double(num)
            } else if let str = value as? String {
                return Double(str)
            }
            return nil
        }
        
        func parseNumberFilters(lower: Any, upper: Any, inclusive: Bool) -> [DatabaseQuery.Filter]? {
            var filters: [DatabaseQuery.Filter] = []
            
            if !isNull(value: lower), let lowerValue = parseNumberRangeBoundary(lower) {
                filters.append(.value(field,
                                      inclusive ? .greaterThanOrEqual : .greaterThan,
                                      .bind(lowerValue)))
            }
            
            if !isNull(value: upper), let upperValue = parseNumberRangeBoundary(upper) {
                filters.append(.value(field,
                                      inclusive ? .lessThanOrEqual : .lessThan,
                                      .bind(upperValue)))
            }
            
            return filters.isEmpty ? nil : filters
        }
        
        func parseDateFilters(lower: Any, upper: Any, inclusive: Bool) -> [DatabaseQuery.Filter]? {
            var filters: [DatabaseQuery.Filter] = []
            
            if !isNull(value: lower),
               let lowerDate = Date(string: "\(lower)") {
                filters.append(.value(field,
                                      inclusive ? .greaterThanOrEqual : .greaterThan,
                                      .bind(lowerDate)))
            }
            
            if !isNull(value: upper),
               let upperDate = Date(string: "\(upper)") {
                filters.append(.value(field,
                                      inclusive ? .lessThanOrEqual : .lessThan,
                                      .bind(upperDate)))
            }
            
            return filters.isEmpty ? nil : filters
        }
        
        func parseStringFilters(lower: Any, upper: Any, inclusive: Bool) -> [DatabaseQuery.Filter]? {
            var filters: [DatabaseQuery.Filter] = []
            
            if !isNull(value: lower) {
                filters.append(.value(field,
                                      inclusive ? .greaterThanOrEqual : .greaterThan,
                                      .bind(String(describing: lower))))
            }
            
            if !isNull(value: upper) {
                filters.append(.value(field,
                                      inclusive ? .lessThanOrEqual : .lessThan,
                                      .bind(String(describing: upper))))
            }
            
            return filters.isEmpty ? nil : filters
        }
        
        switch method {
        case .between, .betweenInclusive, .inNumberRange:
            guard let range = value.value as? [Any], range.count == 2 else {
                throw QueryParameterFilterError.invalidFilterConfiguration
            }
            let lower = range[0]
            let upper = range[1]
            let inclusive = method == .betweenInclusive
            var filters: [DatabaseQuery.Filter]?
            // Try number range first
            if method == .inNumberRange {
                filters = parseNumberFilters(lower: lower, upper: upper, inclusive: inclusive)
            }
            // Try date range
            else if let dateFilters = parseDateFilters(lower: lower, upper: upper, inclusive: inclusive) {
                filters = dateFilters
            }
            // Fall back to string range
            else if let stringFilters = parseStringFilters(lower: lower, upper: upper, inclusive: inclusive) {
                filters = stringFilters
            }
            guard let filters, filters.count != 0 else {
                return nil
            }
            return filters.count > 1 ? .group(filters, .and) : filters[0]
            
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
        case .arrIncludes:
            return .value(field, .overlaps, .bind(["\(value.value)"]))
        case .equalsAny:
            switch value.toDatabaseQueryValue() {
            case .array(let array):
                return .group(array.map {
                    .value(field, .equal, $0)
                }, .or)
                
            default:
                return nil
            }
            
        default:
            return .value(field, method.toDatabaseQueryFilterMethod(), value.toDatabaseQueryValue())
        }
    }
}

/// Extension to add query parameter filtering to query builders
public extension QueryBuilder {
    
    /// Applies a filter from URL query parameters
    /// - Parameters:
    ///   - queryParameterKey: The key in the URL query string containing the filter
    ///   - request: The incoming request
    ///   - builder: Optional custom filter builder
    /// - Returns: The filtered query builder
    func filterWithQueryParameter(at queryParameterKey: String = "filter",
                                  in request: Request,
                                  builder: QueryParameterFilter.Builder<Model>? = nil) throws -> Self {
        guard let filterString: String = request.query[queryParameterKey] else {
            return self
        }
        return try filterWithQueryParameterString(filterString, builder: builder)
    }
    
    /// Applies a filter from a filter string
    /// - Parameters:
    ///   - queryParameterFilterString: The JSON filter string
    ///   - builder: Optional custom filter builder
    /// - Returns: The filtered query builder
    func filterWithQueryParameterString(_ queryParameterFilterString: String,
                                        builder: QueryParameterFilter.Builder<Model>? = nil) throws -> Self {
        if let filterCondition = try DatabaseQuery.Filter.build(from: queryParameterFilterString, builder: builder ?? QueryParameterFilter.Builder<Model>(self)) {
            return self.filter(filterCondition)
        }
        return self
    }
}

extension DatabaseQuery.Filter.Method {
    /// A placeholder filter method used when the actual method needs to be determined at runtime
    static var placeholder: DatabaseQuery.Filter.Method {
        return .custom("")
    }
}

// MARK: - PostgreSQL Extensions
public extension DatabaseQuery.Filter.Method {
    /// PostgreSQL array contains operator (@>)
    static var containsArray: DatabaseQuery.Filter.Method {
        return .custom(SQLRaw("@>"))
    }
    
    /// PostgreSQL array is contained by operator (<@)
    static var isContainedByArray: DatabaseQuery.Filter.Method {
        return .custom(SQLRaw("<@"))
    }
    
    /// PostgreSQL array overlaps operator (&&)
    static var overlaps: DatabaseQuery.Filter.Method {
        return .custom(SQLRaw("&&"))
    }
    
    /// PostgreSQL similar to operator
    static var similarTo: DatabaseQuery.Filter.Method {
        return .custom(SQLRaw("SIMILAR TO"))
    }
    
    /// PostgreSQL full text search operator
    static var fullTextSearch: DatabaseQuery.Filter.Method {
        return .custom(SQLRaw("@@"))
    }
}

/// Extension to support type conversion and database value conversion
public extension AnyCodable {
    /// Converts a value to an appropriate `Encodable` type
    func castToEncodable(value: Any) -> Encodable {
        switch type(of: value) {
        case is Bool.Type:
            if let boolValue = value as? Bool {
                return boolValue
            }
        case is Int.Type:
            if let intValue = value as? Int {
                return intValue
            }
        case is Double.Type:
            if let doubleValue = value as? Double {
                return doubleValue
            }
        case is String.Type:
            if let stringValue = value as? String{
                if let dateValue = Date(string: "\(stringValue)")  {
                    return dateValue
                }
                return stringValue
            }
        default:
            break
        }
        return "\(value)"
    }
    
    /// Gets the inner value as an `Encodable`
    func encodableInnerValue() -> Encodable {
        return castToEncodable(value: value)
    }
    
    /// Converts the value to a database query value
    func toDatabaseQueryValue() -> DatabaseQuery.Value {
        switch value {
        case let arrayValue as [Any]:
            return .array(arrayValue.map { .bind(castToEncodable(value: $0)) })
        default:
            return .bind(self.encodableInnerValue())
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
