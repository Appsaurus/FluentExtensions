//
//  EntityExtensions.swift
//
//
//  Created by Brian Strobach on 11/30/17.
//

import Fluent
import CollectionConcurrencyKit

// MARK: Query public extensions

public extension Model {
    static func find(_ ids: [IDValue], on database: Database) async throws -> [Self] {
        try await query(on: database).filter(\._$id ~~ ids).all()
    }

    /// Attempts to find an instance of this model w/
    /// the supplied value at the given key path
    static func find<V: Encodable & QueryableProperty>(_ keyPath: KeyPath<Self, V>,
                                                       value: V.Value,
                                                       on database: Database) async throws -> Self? {
        try await query(on: database).filter(keyPath == value).first()
    }
}

public extension Model {
    /// Attempts to find all records of this entity w/
    /// the supplied value at the given key path
    static func findAll<V: QueryableProperty & Codable>(_ keyPath: KeyPath<Self, FieldProperty<Self, V>>,
                                                        value: V,
                                                        limit: Int? = nil,
                                                        on database: Database) async throws -> [Self] {
        var query = query(on: database)
            .filter(keyPath == value)
        if let limit {
            query = query.limit(limit)
        }
        return try await query.all().get()
    }

    static func find(where filters: ModelValueFilter<Self>..., on database: Database) async throws -> Self? {
        try await find(where: filters, on: database)
    }

    static func find(where filters: [ModelValueFilter<Self>], on database: Database) async throws -> Self? {
        try await query(on: database).filter(filters).first()
    }

    static func findAll(where filters: ModelValueFilter<Self>..., limit: Int? = nil, on database: Database) async throws -> [Self] {
        try await findAll(where: filters, limit: limit, on: database)
    }

    static func findAll(where filters: [ModelValueFilter<Self>], limit: Int? = nil, on database: Database) async throws -> [Self] {
        var query = query(on: database)
            .filter(filters)
        if let limit {
            query = query.limit(limit)
        }
        return try await query.all().get()        
    }
}
