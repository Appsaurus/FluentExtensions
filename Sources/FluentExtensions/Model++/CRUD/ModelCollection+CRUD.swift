import Vapor
import Fluent
import CollectionConcurrencyKit

public extension Collection where Element: Model {
    /// Creates multiple models in the database.
    /// - Parameters:
    ///   - database: The database connection to perform the creates on
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    /// - Returns: Array of created model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    func create(in database: Database,
                transaction: Bool = true) async throws -> [Element] {
        try await performBatch(.create,
                               on: database,
                               transaction: transaction)
    }

    /// Saves multiple models in the database.
    /// - Parameters:
    ///   - database: The database connection to perform the saves on
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    /// - Returns: Array of saved model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    func save(in database: Database,
              transaction: Bool = true) async throws -> [Element] {
        try await performBatch(.save,
                               on: database,
                               transaction: transaction)
    }
    
    /// Updates multiple models in the database.
    /// - Parameters:
    ///   - database: The database connection to perform the updates on
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    /// - Returns: Array of updated model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    func update(in database: Database,
                transaction: Bool = true) async throws -> [Element] {
        try await performBatch(.update,
                               on: database,
                               transaction: transaction)
    }
    
    /// Deletes multiple models from the database.
    /// - Parameters:
    ///   - database: The database connection to perform the deletes on
    ///   - force: When true, performs force deletes. Defaults to false
    ///   - transaction: When true, wraps the operation in a transaction. Defaults to true
    /// - Returns: Array of deleted model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    func delete(from database: Database, force: Bool = false, transaction: Bool = true) async throws -> [Element]{
        try await performBatch(.delete(force: force),
                               on: database,
                               transaction: transaction
        )
    }
}
