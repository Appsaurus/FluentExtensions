//
//  QueryBuilder+Limit.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 3/10/25.
//

/// Extension providing convenient limit functionality for QueryBuilder
public extension QueryBuilder {
    /// Retrieves at most a specified number of records
    ///
    /// - Parameter max: Maximum number of records to retrieve
    /// - Returns: Array of models limited to the specified count
    /// - Throws: Any database errors that occur during the query execution
    func at(most max: Int) async throws -> [Model] {
        try await limit(max).all()
    }

    /// Retrieves records with an optional limit
    ///
    /// If no limit is provided, returns all matching records.
    ///
    /// - Parameter max: Optional maximum number of records to retrieve
    /// - Returns: Array of models, optionally limited to the specified count
    /// - Throws: Any database errors that occur during the query execution
    func at(most max: Int?) async throws -> [Model] {
        guard let max = max else { return try await all() }
        return try await at(most: max)
    }
}
