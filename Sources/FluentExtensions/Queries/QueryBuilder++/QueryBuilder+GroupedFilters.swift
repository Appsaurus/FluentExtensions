//
//  QueryBuilder+GroupedFilters.swift
//  
//
//  Created by Brian Strobach on 9/14/21.
//

import FluentKit

/// Extension providing grouped filtering capabilities for QueryBuilder
///
/// This extension adds methods for creating compound OR and AND filter groups,
/// allowing for more complex query conditions.
public extension QueryBuilder {
    
    /// Creates an OR group of database filters
    ///
    /// Combines multiple database filters with OR logic, where any of the conditions can match
    /// for a record to be included in the results.
    ///
    /// - Parameter values: Variadic list of DatabaseQuery.Filter conditions
    /// - Returns: Modified QueryBuilder instance with OR filters applied
    func or(_ values: DatabaseQuery.Filter...) -> Self {
        return group(.or) { (or) in
            for value in values {
                or.filter(value)
            }
        }
    }

    /// Creates an AND group of database filters
    ///
    /// Combines multiple database filters with AND logic, where all conditions must match
    /// for a record to be included in the results.
    ///
    /// - Parameter values: Variadic list of DatabaseQuery.Filter conditions
    /// - Returns: Modified QueryBuilder instance with AND filters applied
    func and(_ values: DatabaseQuery.Filter...) -> Self {
        return group(.and) { (and) in
            for value in values {
                and.filter(value)
            }
        }
    }

    /// Creates an OR group of model value filters
    ///
    /// Combines multiple model-specific filters with OR logic, providing a more
    /// type-safe way to create compound conditions.
    ///
    /// - Parameter values: Variadic list of ModelValueFilter conditions
    /// - Returns: Modified QueryBuilder instance with OR filters applied
    func or(_ values: ModelValueFilter<Model>...) -> Self {
        return group(.or) { (or) in
            for value in values {
                or.filter(value)
            }
        }
    }

    /// Creates an AND group of model value filters
    ///
    /// Combines multiple model-specific filters with AND logic, providing a more
    /// type-safe way to create compound conditions.
    ///
    /// - Parameter values: Variadic list of ModelValueFilter conditions
    /// - Returns: Modified QueryBuilder instance with AND filters applied
    func and(_ values: ModelValueFilter<Model>...) -> Self {
        return group(.and) { (and) in
            for value in values {
                and.filter(value)
            }
        }
    }
}
