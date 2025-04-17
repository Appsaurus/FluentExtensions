//
//  QueryBuilder+GroupBy.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 3/10/25.
//

/// Extension providing convenient grouping functionality for QueryBuilder
public extension QueryBuilder {
    
    /// Groups the query results by a specific field with optional nil handling
    /// 
    /// This method allows for convenient grouping with optional field paths, safely handling nil values
    /// by returning the unmodified query builder if the field is nil.
    ///
    /// - Parameter field: Optional KeyPath to the field to group by
    /// - Returns: Modified QueryBuilder instance with grouping applied, or unmodified if field is nil
    @discardableResult
    func groupBy<T>(_ field: KeyPath<Model, T>?) -> Self {
        guard let field = field else { return self }
        return groupBy(field)
    }

    /// Retrieves grouped distinct values for a specific field
    ///
    /// This method combines grouping and value extraction to efficiently fetch distinct values
    /// for a specified field. Useful for aggregation queries or obtaining unique field values.
    ///
    /// - Parameters:
    ///   - field: KeyPath to the field whose values should be grouped and retrieved
    ///   - limit: Optional maximum number of results to return
    /// - Returns: Array of distinct values for the specified field
    /// - Throws: Any database errors that occur during the query execution
    func groupedValues<T>(of field: KeyPath<Model, T>, limit: Int?) async throws -> [T] {
        try await groupBy(field).values(of: field, limit: limit)
    }
}
