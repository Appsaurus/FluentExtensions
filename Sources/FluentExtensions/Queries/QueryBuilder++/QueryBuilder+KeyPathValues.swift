//
//  QueryBuilder+KeyPathValues.swift
//  
//
//  Created by Brian Strobach on 10/25/21.
//

import Fluent

/// Extension providing KeyPath-based value extraction capabilities for QueryBuilder
public extension QueryBuilder {
    /// Retrieves values for a specific field with optional limit
    ///
    /// Efficiently extracts values for a specified field from query results without fetching entire model instances.
    ///
    /// - Parameters:
    ///   - field: KeyPath to the field whose values should be retrieved
    ///   - limit: Optional maximum number of results to return
    /// - Returns: Array of values for the specified field
    /// - Throws: Any database errors that occur during the query execution
    func values<T>(of field: KeyPath<Model, T>, limit: Int?) async throws -> [T] {
        let models = try await at(most: limit)
        return models.map { $0[keyPath: field] }
    }
    
    /// Retrieves all non-optional values for a specific field
    ///
    /// - Parameter keyPath: KeyPath to the field whose values should be retrieved
    /// - Returns: Array of non-optional values for the specified field
    /// - Throws: Any database errors that occur during the query execution
    func allValues<V>(at keyPath: KeyPath<Model, V>) async throws -> [V] {
        let allModels = try await all()
        return allModels.map { $0[keyPath: keyPath] }
    }

    /// Retrieves all non-nil values for an optional field
    ///
    /// - Parameter keyPath: KeyPath to the optional field whose values should be retrieved
    /// - Returns: Array of non-nil values for the specified field
    /// - Throws: Any database errors that occur during the query execution
    func allValues<V>(at keyPath: KeyPath<Model, V?>) async throws -> [V] {
        let allModels = try await all()
        return allModels.compactMap { $0[keyPath: keyPath] }
    }

    /// Retrieves all model IDs from the query results
    ///
    /// - Returns: Array of model ID values
    /// - Throws: Any database errors that occur during the query execution
    func allIDs() async throws -> [Model.IDValue] {
        try await allValues(at: \.id)
    }
}
