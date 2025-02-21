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
            
        }
        guard let filter else {
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
        query.filters.append(filter)
        return self
//
//        switch (queryParameterFilter.method, queryParameterFilter.value) {
//            // Basic comparisons
//        case let (.equals, .single(value)):
//            return self.filter(queryField, .equal, try queryParameterFilter.encodableValue(for: value))
//        case let (.notEquals, .single(value)):
//            return self.filter(queryField, .notEqual, try queryParameterFilter.encodableValue(for: value))
//        case let (.greaterThan, .single(value)):
//            return self.filter(queryField, .greaterThan, try queryParameterFilter.encodableValue(for: value))
//        case let (.greaterThanOrEqualTo, .single(value)):
//            return self.filter(queryField, .greaterThanOrEqual, try queryParameterFilter.encodableValue(for: value))
//        case let (.lessThan, .single(value)):
//            return self.filter(queryField, .lessThan, try queryParameterFilter.encodableValue(for: value))
//        case let (.lessThanOrEqualTo, .single(value)):
//            return self.filter(queryField, .lessThanOrEqual, try queryParameterFilter.encodableValue(for: value))
//            
//            // Check value against Array
//        case let (.arrIncludes, .multiple(value)):
//            return self.filter(queryField, .inSubSet, try queryParameterFilter.encodableValue(for: value))
//        case let (.arrNotIncludes, .multiple(value)):
//            return self.filter(queryField, .notInSubSet, try queryParameterFilter.encodableValue(for: value))
//            
//            // Check Array against Array
//        case let (.arrIncludesAll, .multiple(values)):
//            return self.filter(queryField, .containsArray, try queryParameterFilter.encodableValue(for: values))
//        case let (.arrIncludesSome, .multiple(values)):
//            return self.filter(queryField, .overlaps, try queryParameterFilter.encodableValue(for: values))
//        case let (.arrIsContainedBy, .multiple(values)):
//            return self.filter(queryField, .isContainedByArray, try queryParameterFilter.encodableValue(for: values))
//            
//            
//            // String operations
//        case let (.contains, .single(value)):
//            return self.filter(queryField, .contains(inverse: false, .anywhere), try queryParameterFilter.encodableValue(for: value))
//        case let (.startsWith, .single(value)):
//            return self.filter(queryField, .contains(inverse: false, .prefix), try queryParameterFilter.encodableValue(for: value))
//        case let (.notStartsWith, .single(value)):
//            return self.filter(queryField, .contains(inverse: true, .prefix), try queryParameterFilter.encodableValue(for: value))
//        case let (.endsWith, .single(value)):
//            return self.filter(queryField, .contains(inverse: false, .suffix), try queryParameterFilter.encodableValue(for: value))
//        case let (.notEndsWith, .single(value)):
//            return self.filter(queryField, .contains(inverse: true, .suffix), try queryParameterFilter.encodableValue(for: value))
//            
//            // Empty string checks
//        case (.empty, _):
//            return self.filter(queryField, .equal, .bind(""))
//        case (.notEmpty, _):
//            return self.filter(queryField, .notEqual, .bind(""))
//                                                           
//            // Null checks
//        case (.isNull, _):
//            return self.filter(queryField, .equal, .null)
//        case (.isNotNull, _):
//            return self.filter(queryField, .notEqual, .null)
//            
//            // Range operations
//        case let (.between, .multiple(values)), let (.betweenInclusive, .multiple(values)):
//            guard values.count == 2 else { throw QueryParameterFilterError.invalidRangeValues }
//            let lowerBound = try queryParameterFilter.encodableValue(for: values[0])
//            let upperBound = try queryParameterFilter.encodableValue(for: values[1])
//            
//            let method: DatabaseQuery.Filter.Method = queryParameterFilter.method == .betweenInclusive ? .greaterThanOrEqual : .greaterThan
//            let upperMethod: DatabaseQuery.Filter.Method = queryParameterFilter.method == .betweenInclusive ? .lessThanOrEqual : .lessThan
//            
//            return self
//                .filter(queryField, method, lowerBound)
//                .filter(queryField, upperMethod, upperBound)
//            
//            // PostgreSQL specific operations
//        case let (.fuzzy, .single(value)):
//            return self.filter(queryField, .similarTo, try queryParameterFilter.encodableValue(for: value))
//        case let (.searchText, .single(value)):
//            return self.filter(queryField, .fullTextSearch, try queryParameterFilter.encodableValue(for: value))
//            
//        default:
//            throw QueryParameterFilterError.invalidFilterConfiguration
//        }
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
