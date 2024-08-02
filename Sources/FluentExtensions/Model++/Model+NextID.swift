//
//  Model+NextID.swift
//
//
//  Created by Brian Strobach on 9/2/21.
//

import Fluent
import CollectionConcurrencyKit

public extension Model where IDValue == Int {
    static func nextID(on database: Database) async throws -> IDValue {
        let value = try await query(on: database).sort(\._$id, .descending).first()
        return (value?.id ?? -1) + 1
    }
}

public extension QueryBuilder {
    // MARK: Range
    func at(most max: Int) async throws -> [Model] {
        try await limit(max).all()
    }

    func at(most max: Int?) async throws -> [Model] {
        guard let max = max else { return try await all() }
        return try await at(most: max)
    }
}

public extension QueryBuilder {
    @discardableResult
    func groupBy<T>(_ field: KeyPath<Model, T>?) -> Self {
        guard let field = field else { return self }
        return groupBy(field)
    }

    func groupedValues<T>(of field: KeyPath<Model, T>, limit: Int?) async throws -> [T] {
        try await groupBy(field).values(of: field, limit: limit)
    }

    func values<T>(of field: KeyPath<Model, T>, limit: Int?) async throws -> [T] {
        let models = try await at(most: limit)
        return models.map { $0[keyPath: field] }
    }
}

public extension QueryBuilder {
    @discardableResult
    func filter(_ filters: ModelValueFilter<Model>...) -> Self {
        filter(filters)
    }

    @discardableResult
    func filter(_ filters: [ModelValueFilter<Model>]) -> Self {
        filters.reduce(self) { $0.filter($1) }
    }
}

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
