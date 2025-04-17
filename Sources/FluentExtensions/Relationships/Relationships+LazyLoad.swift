//
//  Relationships+LazyLoad.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 3/9/25.
//

import Fluent

/// Extension providing lazy loading capabilities for Fluent relationships.
///
/// This extension adds convenient functionality to conditionally load relationship data
/// only when needed, helping to optimize database queries and memory usage.
public extension Relation {
    /// Loads the relationship data if it hasn't been loaded yet or if a reload is requested.
    ///
    /// This method provides an efficient way to ensure relationship data is available when needed
    /// while avoiding unnecessary database queries for already loaded relationships.
    ///
    /// - Parameters:
    ///   - reload: A boolean flag indicating whether to force reload the relationship data even if it's already loaded.
    ///             Defaults to `false`.
    ///   - database: The database connection to use for loading the relationship.
    /// - Throws: Any errors that occur during the database query or relationship loading process.
    func loadIfNeeded(reload: Bool = false, on database: Database) async throws {
        if let _ = self.value, !reload {
            return
        } else {
            try await self.load(on: database).get()
        }
    }
}
