import Foundation
import Fluent
import Vapor
import CollectionConcurrencyKit

public extension Collection where Element: Model {
    /// Updates multiple models using the specified update method.
    /// - Parameters:
    ///   - method: The update method to use (upsert, update, or save)
    ///   - database: The database connection to perform the updates on
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    /// - Returns: Array of updated model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    func updateBy(_ method: UpdateMethod,
                  in database: Database,
                  transaction: Bool = true) async throws -> [Element] {
        switch method {
        case .upsert:
            return try await upsert(in: database, transaction: transaction)
        case .update:
            return try await update(in: database, force: true, transaction: transaction)
        case .save:
            return try await save(in: database, transaction: transaction)
        }
    }
    
    /// Updates multiple models with optional force flag.
    /// - Parameters:
    ///   - database: The database connection to perform the updates on
    ///   - force: When true, marks models as existing before update. Defaults to true
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    /// - Returns: Array of updated model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    func update(in database: Database,
                force: Bool = true,
                transaction: Bool = true) async throws -> [Element] {
        try await performBatch(
            action: { element, db in
                try await element.update(in: db, force: force)
            },
            on: database,
            transaction: transaction
        )
    }

    /// Creates or updates multiple models based on their existence in the database.
    /// - Parameters:
    ///   - database: The database connection to perform the operations on
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    /// - Returns: Array of created or updated model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    func upsert(in database: Database,
                transaction: Bool = true) async throws -> [Element] {
        try await performBatch(
            action: { element, db in
                try await element.upsert(in: db)
            },
            on: database,
            transaction: transaction
        )
    }

    /// Updates multiple models only if they exist in the database.
    /// - Parameters:
    ///   - database: The database connection to perform the updates on
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    /// - Returns: Array of updated model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    func updateIfExists(in database: Database,
                transaction: Bool = true) async throws -> [Element] {
        try await performBatch(
            action: { element, db in
                try await element.updateIfExists(in: db)
            },
            on: database,
            transaction: transaction
        )
    }

    /// Replaces multiple models with new instances.
    /// - Parameters:
    ///   - models: The new model instances to create after deletion
    ///   - database: The database connection to perform the operations on
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    /// - Returns: Array of newly created model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    func replace(with models: [Element],
                 in database: Database,
                transaction: Bool = true) async throws -> [Element] {
        try await performBatch(
            action: { element, db in
                try await element.replace(with: element, on: db)
            },
            on: database,
            transaction: transaction
        )
    }
    
    /// Restores multiple soft-deleted models.
    /// - Parameter database: The database connection to perform the restores on
    /// - Returns: The collection of restored models
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    func restore(on database: Database) async throws -> Self {
        guard self.count > 0 else { return self }
        
        for model in self {
            try await model.restore(on: database)
        }
        return self
    }
    
    /// Restores multiple soft-deleted models with optional transaction support.
    /// - Parameters:
    ///   - database: The database connection to perform the restores on
    ///   - transaction: When true, wraps the operation in a transaction
    /// - Returns: The collection of restored models
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    func restore(on database: Database, transaction: Bool) async throws -> Self {
        if transaction {
            return try await database.transaction { transaction in
                try await restore(on: transaction)
            }
        } else {
            return try await restore(on: database)
        }
    }
}
