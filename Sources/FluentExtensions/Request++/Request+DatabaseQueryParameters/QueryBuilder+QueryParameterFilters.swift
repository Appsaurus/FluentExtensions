import Fluent
import RuntimeExtensions
import CodableExtensions
import Codability

///QueryBuilder extensions for handling query parameter filters in Fluent database operations.
public extension QueryBuilder {
    
    /// Applies a query parameter filter to the current query builder.
    ///
    /// This method processes different types of filter values (single, multiple, or range) and applies them
    /// to the database query using the specified filter method.
    ///
    /// - Parameter queryParameterFilter: The filter configuration to apply to the query
    /// - Returns: The modified query builder instance
    /// - Throws: `QueryParameterFilterError` if the filter configuration is invalid
    @discardableResult
    func filter(_ queryParameterFilter: QueryParameterFilter) throws -> QueryBuilder<Model> {
        let queryField = queryParameterFilter.queryField()
        
        var filter: DatabaseQuery.Filter? = nil
        switch queryParameterFilter.value {
        case .single(let singleValue):
            filter = try .buildSimpleFilter(field: queryField,
                                            method: queryParameterFilter.method,
                                            value: AnyCodable(queryParameterFilter.encodableValue(for: singleValue)))
        case .multiple(let multipleValues):
            filter = try .buildSimpleFilter(field: queryField,
                                            method: queryParameterFilter.method,
                                            value: AnyCodable(queryParameterFilter.encodableValue(for: multipleValues)))
        case .range(let rangeValue):
            filter = try .buildSimpleFilter(field: queryField,
                                            method: queryParameterFilter.method,
                                            value: AnyCodable(queryParameterFilter.encodableValue(for: rangeValue)))
        }
        
        guard let filter else {
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
        query.filters.append(filter)
        return self
    }
    
    /// Applies a simple filter with a single value to the query builder.
    ///
    /// - Parameters:
    ///   - field: The database field to filter on
    ///   - method: The filter method to apply
    ///   - value: The value to filter by
    /// - Returns: The modified query builder instance
    @discardableResult
    fileprivate func filter(_ field: DatabaseQuery.Field,
                            _ method: DatabaseQuery.Filter.Method,
                            _ value: Encodable) -> QueryBuilder<Model>{
        self.filter(.value(field, method, DatabaseQuery.Value.bind(value)))
        return self
    }
    
    /// Applies a filter with multiple values to the query builder.
    ///
    /// - Parameters:
    ///   - field: The database field to filter on
    ///   - method: The filter method to apply
    ///   - value: An array of values to filter by
    /// - Returns: The modified query builder instance
    @discardableResult
    fileprivate func filter(_ field: DatabaseQuery.Field,
                            _ method: DatabaseQuery.Filter.Method,
                            _ value: [Encodable]) -> QueryBuilder<Model>{
        let values = value.map({DatabaseQuery.Value.bind($0)})
        self.filter(.value(field, method, DatabaseQuery.Value.array(values)))
        return self
    }
}

/// Errors that can occur during query parameter filtering operations.
///
/// These errors provide specific feedback about what went wrong during the filtering process.
public enum QueryParameterFilterError: Error, LocalizedError, CustomStringConvertible {
    /// Indicates that the filter configuration is not valid
    case invalidFilterConfiguration
    /// Indicates that the range values provided are not valid (must be exactly two values)
    case invalidRangeValues
    /// Indicates that the requested filter operation is not supported
    case unsupportedFilterOperation
    
    public var description: String {
        switch self {
        case .invalidFilterConfiguration:
            return "Invalid filter configuration."
        case .invalidRangeValues:
            return "Range operations require exactly two values."
        case .unsupportedFilterOperation:
            return "The requested filter operation is not supported."
        }
    }
    
    public var errorDescription: String? {
        return self.description
    }
}
