//
//  Model+TableActions.swift
//
//
//  Created by Brian Strobach on 9/2/21.
//

import Fluent
import VaporExtensions

// MARK: - Table Operations
public extension Model {
    /// Deletes all records of this model type from the database
    /// - Parameters:
    ///   - force: When true, performs force deletes. Defaults to false
    ///   - database: The database connection to perform the deletion on
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    /// - Throws: Any database errors that occur during the operation
    static func deleteAll(force: Bool = false, in database: Database, transaction: Bool = true) async throws -> Void {
        let models = try await query(on: database).all()
        try await models.delete(from: database, force: force, transaction: transaction)
    }

    /// Updates all records of this model type in the database
    /// - Parameters:
    ///   - database: The database connection to perform the updates on
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    /// - Returns: Array of updated model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    static func updateAll(in database: Database, transaction: Bool = true) async throws -> [Self] {
        let models = try await query(on: database).all()
        return try await models.update(in: database, transaction: transaction)
    }

    /// Updates all records using a modification closure
    /// - Parameters:
    ///   - database: The database connection to perform the updates on
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    ///   - modifications: A closure that modifies each model instance
    /// - Returns: Array of updated model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    static func updateAll(
        in database: Database,
        transaction: Bool = true,
        modifications: @escaping (Self) -> Self
    ) async throws -> [Self] {
        let models = try await query(on: database).all()
        let modifiedModels = models.map(modifications)
        return try await modifiedModels.update(in: database, transaction: transaction)
    }

    /// Updates all records using a throwing modification closure
    /// - Parameters:
    ///   - database: The database connection to perform the updates on
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    ///   - modifications: A throwing closure that modifies each model instance
    /// - Returns: Array of updated model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    static func updateAllThrowing(
        in database: Database,
        transaction: Bool = true,
        modifications: @escaping (Self) throws -> Self
    ) async throws -> [Self] {
        let models = try await query(on: database).all()
        let modifiedModels = try await withThrowingTaskGroup(of: Self.self) { group in
            for model in models {
                group.addTask {
                    try modifications(model)
                }
            }
            return try await group.reduce(into: [Self]()) { result, model in
                result.append(model)
            }
        }
        return try await modifiedModels.update(in: database, transaction: transaction)
    }

    /// Updates all records using an async modification closure
    /// - Parameters:
    ///   - database: The database connection to perform the updates on
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    ///   - modifications: An async closure that modifies each model instance
    /// - Returns: Array of updated model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    static func updateAllAsync(
        in database: Database,
        transaction: Bool = true,
        modifications: @escaping (Self) async -> Self
    ) async throws -> [Self] {
        let models = try await query(on: database).all()
        let modifiedModels = await withTaskGroup(of: Self.self) { group in
            for model in models {
                group.addTask {
                    await modifications(model)
                }
            }
            return await group.reduce(into: [Self]()) { result, model in
                result.append(model)
            }
        }
        return try await modifiedModels.update(in: database, transaction: transaction)
    }

    /// Selectively updates records based on a modification closure
    /// - Parameters:
    ///   - database: The database connection to perform the updates on
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    ///   - modifications: A closure that optionally modifies each model instance
    /// - Returns: Array of updated model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    static func updateAllSelectively(
        in database: Database,
        transaction: Bool = true,
        modifications: @escaping (Self) -> Self?
    ) async throws -> [Self] {
        let models = try await query(on: database).all()
        let modifiedModels = models.compactMap(modifications)
        return try await modifiedModels.update(in: database, transaction: transaction)
    }

    /// Selectively updates records based on a throwing modification closure
    /// - Parameters:
    ///   - database: The database connection to perform the updates on
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    ///   - continueOnError: When true, continues processing if an error occurs
    ///   - modifications: A throwing closure that optionally modifies each model instance
    /// - Returns: Array of updated model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    static func updateAllSelectivelyThrowing(
        in database: Database,
        transaction: Bool = true,
        continueOnError: Bool = false,
        modifications: @escaping (Self) throws -> Self?
    ) async throws -> [Self] {
        let models = try await query(on: database).all()
        let modifiedModels = try await withThrowingTaskGroup(of: Self?.self) { group in
            for model in models {
                group.addTask {
                    try modifications(model)
                }
            }
            return try await group.reduce(into: [Self]()) { result, model in
                if let model = model {
                    result.append(model)
                }
            }
        }
        return try await modifiedModels.update(in: database, transaction: transaction)
    }

    /// Selectively updates records based on an async modification closure
    /// - Parameters:
    ///   - database: The database connection to perform the updates on
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    ///   - modifications: An async closure that optionally modifies each model instance
    /// - Returns: Array of updated model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    static func updateAllSelectivelyAsync(
        in database: Database,
        transaction: Bool = true,
        modifications: @escaping (Self) async -> Self?
    ) async throws -> [Self] {
        let models = try await query(on: database).all()
        let modifiedModels = await withTaskGroup(of: Self?.self) { group in
            for model in models {
                group.addTask {
                    await modifications(model)
                }
            }
            return await group.reduce(into: [Self]()) { result, model in
                if let model = model {
                    result.append(model)
                }
            }
        }
        return try await modifiedModels.update(in: database, transaction: transaction)
    }
}

// MARK: - Helper Functions
fileprivate extension Sequence {
    /// Removes nil values from a sequence of optional elements
    /// - Returns: Array of non-nil elements
    func removeNils<T>() -> [T] where Element == T? {
        compactMap { $0 }
    }
}
