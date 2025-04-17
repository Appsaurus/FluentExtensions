//
//  Model+GroupByQueries.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 3/10/25.
//

public extension Model {
    /// Finds all model instances that match specified filters with optional grouping
    /// - Parameters:
    ///   - filters: The filters to apply to the query
    ///   - groupKey: Optional key path to group results by
    ///   - limit: Optional limit on number of results
    ///   - database: The database connection to query
    /// - Returns: Array of matching model instances, optionally grouped
    /// - Throws: Any database errors that occur during the query
    static func findAll<G>(where filters: ModelValueFilter<Self>...,
                           groupedBy groupKey: KeyPath<Self, G>? = nil,
                           limit: Int? = nil, on database: Database) async throws -> [Self] {
        try await findAll(where: filters, groupedBy: groupKey, limit: limit, on: database)
    }

    /// Finds all model instances that match an array of filters with optional grouping
    /// - Parameters:
    ///   - filters: Array of filters to apply to the query
    ///   - groupKey: Optional key path to group results by
    ///   - limit: Optional limit on number of results
    ///   - database: The database connection to query
    /// - Returns: Array of matching model instances, optionally grouped
    /// - Throws: Any database errors that occur during the query
    static func findAll<G>(where filters: [ModelValueFilter<Self>],
                           groupedBy groupKey: KeyPath<Self, G>? = nil,
                           limit: Int? = nil,
                           on database: Database) async throws -> [Self] {
        try await query(on: database).filter(filters).groupBy(groupKey).at(most: limit)
    }

    /// Retrieves grouped values for a specific field that match the given filters
    /// - Parameters:
    ///   - field: The field to retrieve values from
    ///   - filters: Array of filters to apply to the query
    ///   - limit: Optional limit on number of results
    ///   - database: The database connection to query
    /// - Returns: Array of grouped field values
    /// - Throws: Any database errors that occur during the query
    static func groupedValue<V>(of field: KeyPath<Self, V>,
                                where filters: [ModelValueFilter<Self>],
                                limit: Int?,
                                on database: Database) async throws -> [V] {
        try await query(on: database).filter(filters).groupedValues(of: field, limit: limit)
    }

    // Uncomment and update if needed
    // static func uniqueValues<T>(of field: KeyPath<Self, T>, limit: Int?) async throws -> [T] {
    //     try await query(on: database).groupBy(field).values(of: field, limit: limit)
    // }
}
