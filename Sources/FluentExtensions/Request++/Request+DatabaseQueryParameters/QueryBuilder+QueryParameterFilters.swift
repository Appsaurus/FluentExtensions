//
//  QueryBuilder+QueryParameterFilters.swift
//
//
//  Created by Brian Strobach on 9/7/21.
//

import Fluent
import RuntimeExtensions
import CodableExtensions
import Codability

public extension QueryBuilder {
    
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
    
    
    
    @discardableResult
    fileprivate func filter(_ field: DatabaseQuery.Field,
                            _ method: DatabaseQuery.Filter.Method,
                            _ value: Encodable) -> QueryBuilder<Model>{
        self.filter(.value(field, method, DatabaseQuery.Value.bind(value)))
        return self
    }
    
    
    @discardableResult
    fileprivate func filter(_ field: DatabaseQuery.Field,
                            _ method: DatabaseQuery.Filter.Method,
                            _ value: [Encodable]) -> QueryBuilder<Model>{
        let values = value.map({DatabaseQuery.Value.bind($0)})
        self.filter(.value(field, method, DatabaseQuery.Value.array(values)))
        return self
    }
}

public enum QueryParameterFilterError: Error, LocalizedError, CustomStringConvertible {
    case invalidFilterConfiguration
    case invalidRangeValues
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
