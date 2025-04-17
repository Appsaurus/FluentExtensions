//
//  EntityExtensions.swift
//
//
//  Created by Brian Strobach on 11/30/17.
//

import Fluent
import CollectionConcurrencyKit

// MARK: - Query Extensions
public extension Model {
    /// Finds multiple model instances by their IDs
    /// - Parameters:
    ///   - ids: Array of ID values to search for
    ///   - database: The database connection to search in
    /// - Returns: Array of found model instances
    /// - Throws: Any database errors that occur during the search
    static func find(_ ids: [IDValue], on database: Database) async throws -> [Self] {
        try await query(on: database).filter(\._$id ~~ ids).all()
    }

    /// Attempts to find a model instance by matching a property value
    /// - Parameters:
    ///   - keyPath: The key path to the property to match
    ///   - value: The value to match against
    ///   - database: The database connection to search in
    /// - Returns: The matching model instance if found, nil otherwise
    /// - Throws: Any database errors that occur during the search
    static func find<V: Encodable & QueryableProperty>(_ keyPath: KeyPath<Self, V>,
                                                   value: V.Value,
                                                   on database: Database) async throws -> Self? {
        try await query(on: database).filter(keyPath == value).first()
    }
}

public extension Model {
    /// Finds all model instances that match a specific field value
    /// - Parameters:
    ///   - keyPath: The key path to the field to match
    ///   - value: The value to match against
    ///   - limit: Optional limit on the number of results
    ///   - database: The database connection to search in
    /// - Returns: Array of matching model instances
    /// - Throws: Any database errors that occur during the search
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

    /// Finds a model instance using one or more filters
    /// - Parameters:
    ///   - filters: The filters to apply
    ///   - database: The database connection to search in
    /// - Returns: The matching model instance if found, nil otherwise
    /// - Throws: Any database errors that occur during the search
    static func find(where filters: ModelValueFilter<Self>..., on database: Database) async throws -> Self? {
        try await find(where: filters, on: database)
    }

    /// Finds a model instance using an array of filters
    /// - Parameters:
    ///   - filters: Array of filters to apply
    ///   - database: The database connection to search in
    /// - Returns: The matching model instance if found, nil otherwise
    /// - Throws: Any database errors that occur during the search
    static func find(where filters: [ModelValueFilter<Self>], on database: Database) async throws -> Self? {
        try await query(on: database).filter(filters).first()
    }

    /// Finds all model instances that match the specified filters
    /// - Parameters:
    ///   - filters: The filters to apply
    ///   - limit: Optional limit on the number of results
    ///   - database: The database connection to search in
    /// - Returns: Array of matching model instances
    /// - Throws: Any database errors that occur during the search
    static func findAll(where filters: ModelValueFilter<Self>..., limit: Int? = nil, on database: Database) async throws -> [Self] {
        try await findAll(where: filters, limit: limit, on: database)
    }

    /// Finds all model instances that match an array of filters
    /// - Parameters:
    ///   - filters: Array of filters to apply
    ///   - limit: Optional limit on the number of results
    ///   - database: The database connection to search in
    /// - Returns: Array of matching model instances
    /// - Throws: Any database errors that occur during the search
    static func findAll(where filters: [ModelValueFilter<Self>], limit: Int? = nil, on database: Database) async throws -> [Self] {
        var query = query(on: database)
            .filter(filters)
        if let limit {
            query = query.limit(limit)
        }
        return try await query.all().get()        
    }
}
