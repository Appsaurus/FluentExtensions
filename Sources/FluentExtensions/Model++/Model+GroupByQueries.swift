//
//  Model+GroupByQueries.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 3/10/25.
//


public extension Model {
    static func findAll<G>(where filters: ModelValueFilter<Self>...,
                           groupedBy groupKey: KeyPath<Self, G>? = nil,
                           limit: Int? = nil, on database: Database) async throws -> [Self] {
        try await findAll(where: filters, groupedBy: groupKey, limit: limit, on: database)
    }

    static func findAll<G>(where filters: [ModelValueFilter<Self>],
                           groupedBy groupKey: KeyPath<Self, G>? = nil,
                           limit: Int? = nil,
                           on database: Database) async throws -> [Self] {
        try await query(on: database).filter(filters).groupBy(groupKey).at(most: limit)
    }

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