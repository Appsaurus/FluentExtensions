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
    func filter(_ queryParameterFilter: QueryParameterFilter) throws -> QueryBuilder<Model>{
        
        let queryField = queryParameterFilter.queryField()
        //        let encodableValue: AnyCodable = queryParameterFilter.value.to(type: type)
        switch (queryParameterFilter.method, queryParameterFilter.value) {
        case let (.equal, .single(value)): // Equal
            return self.filter(queryField, .equal, try queryParameterFilter.encodableValue(for: value))
        case let (.notEqual, .single(value)): // Not Equal
            return self.filter(queryField, .notEqual, try queryParameterFilter.encodableValue(for: value))
        case let (.greaterThan, .single(value)): // Greater Than
            return self.filter(queryField, .greaterThan, try queryParameterFilter.encodableValue(for: value))
        case let (.greaterThanOrEqual, .single(value)): // Greater Than Or Equal
            return self.filter(queryField, .greaterThanOrEqual, try queryParameterFilter.encodableValue(for: value))
        case let (.lessThan, .single(value)): // Less Than
            return self.filter(queryField, .lessThan, try queryParameterFilter.encodableValue(for: value))
        case let (.lessThanOrEqual, .single(value)): // Less Than Or Equal
            return self.filter(queryField, .lessThanOrEqual, try queryParameterFilter.encodableValue(for: value))
        case let (.in, .multiple(value)): // In
            return self.filter(queryField, .inSubSet, try queryParameterFilter.encodableValue(for: value))
        case let (.notIn, .multiple(value)): // Not In
            return self.filter(queryField, .notInSubSet, try queryParameterFilter.encodableValue(for: value))
        default:
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
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
    
    
    public var description: String {
        switch self {
        case .invalidFilterConfiguration:
            return "Invalid filter config."
        }
    }
    
    public var errorDescription: String? {
        return self.description
    }
}

