//
//  QueryBuilderExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/28/18.
//

import FluentKit

/// Extension providing random record selection capabilities to Model
public extension Model {
    /// Fetches a random record from the database
    /// - Parameter database: The database to query
    /// - Returns: A random instance of the model, if any exist
    static func random(on database: Database) async throws -> Self? {
        try await query(on: database).random()
    }
    
    /// Fetches multiple random records from the database
    /// - Parameters:
    ///   - database: The database to query
    ///   - count: The number of random records to fetch
    /// - Returns: An array of random model instances
    static func random(on database: Database, count: Int) async throws -> [Self] {
        try await query(on: database).randomSlice(count: count)
    }
}

/// Extension providing random record selection capabilities to QueryBuilder
public extension QueryBuilder {
    /// Adds a sort clause to the query
    /// - Parameters:
    ///   - field: The field name to sort by
    ///   - direction: The sort direction
    /// - Returns: The query builder for chaining
    func sort(_ field: String, _ direction: DatabaseQuery.Sort.Direction = .ascending) -> Self {
        return self.sort(FieldKey(extendedGraphemeClusterLiteral: field), direction)
    }

    /// Fetches a single random record matching the query
    /// - Returns: A random model instance, if any exist
    func random() async throws -> Model? {
        let randomModels = try await randomSlice(count: 1)
        return randomModels.first
    }

    /// Fetches multiple random records matching the query
    /// - Parameter count: The number of random records to fetch
    /// - Returns: An array of random model instances
    func randomSlice(count: Int) async throws -> [Model] {
        let total = try await self.count()
        guard total > 0 else { return [] }
        let queryRange = (0..<total).randomSubrange(count)
        return try await self.range(queryRange).all()
    }
}
