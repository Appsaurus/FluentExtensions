import FluentKit
import CollectionConcurrencyKit

/// Type alias for an asynchronous batch operation that takes a value and database and returns a result
public typealias AsyncBatchAction<V, R> = (V, Database) async throws -> R

/// Enumeration of available Fluent database commands
public enum FluentCommand {
    /// Creates a new record
    case create
    /// Saves a record (creates or updates)
    case save
    /// Updates an existing record
    case update
    /// Creates or updates a record based on existence
    case upsert
    /// Deletes a record with optional force flag
    case delete(force: Bool)
    
    /// Returns the appropriate async database action for the command
    /// - Returns: An async closure that performs the database operation
    func action<Value: Model>() -> AsyncBatchAction<Value, Value> {
        return { (element: Value, database: Database) in
            switch self {
            case .create:
                return try await element.create(in: database)
            case .update:
                return try await element.update(in: database)
            case .upsert:
                return try await element.upsert(in: database)
            case .save:
                return try await element.save(in: database)
            case .delete(let force):
                return try await element.delete(from: database, force: force)
            }
        }
    }
}

extension Database {
    /// Performs a batch operation on a collection of inputs.
    /// - Parameters:
    ///   - action: The async operation to perform on each element
    ///   - resources: The collection of elements to process
    ///   - transaction: When true, wraps all operations in a transaction. Defaults to true
    ///   - concurrently: When true, processes operations concurrently. Defaults to true
    /// - Returns: Array of operation results
    /// - Throws: Any database errors that occur during the operations
    @discardableResult
    func performBatch<Input: Collection, Output>(
        action: @escaping AsyncBatchAction<Input.Element, Output>,
        on resources: Input,
        transaction: Bool = true,
        concurrently: Bool = true
    ) async throws -> [Output] {
        let batchOperation = { db in
            if concurrently {
                return try await resources.concurrentMap { element in
                    try await action(element, db)
                }
            } else {
                return try await resources.asyncMap { element in
                    try await action(element, db)
                }
            }
        }
        
        if transaction {
            return try await self.transaction { db in
                try await batchOperation(db)
            }
        } else {
            return try await batchOperation(self)
        }
    }
}

public extension Collection where Element: Model {
    /// Performs a batch operation using a Fluent command.
    /// - Parameters:
    ///   - command: The Fluent command to execute
    ///   - database: The database connection to perform the operations on
    ///   - transaction: When true, wraps operations in a transaction. Defaults to true
    ///   - concurrently: When true, processes operations concurrently. Defaults to true
    /// - Returns: Array of processed model instances
    /// - Throws: Any database errors that occur during the operations
    func performBatch(
        _ command: FluentCommand,
        on database: Database,
        transaction: Bool = true,
        concurrently: Bool = true
    ) async throws -> [Element] {
        return try await performBatch(action: command.action(),
                                      on: database,
                                      transaction: transaction,
                                      concurrently: concurrently)
    }
    
    /// Performs a custom batch operation that returns model instances.
    /// - Parameters:
    ///   - action: The custom operation to perform
    ///   - database: The database connection to perform the operations on
    ///   - transaction: When true, wraps operations in a transaction. Defaults to true
    ///   - concurrently: When true, processes operations concurrently. Defaults to true
    /// - Returns: Array of processed model instances
    /// - Throws: Any database errors that occur during the operations
    func performBatch(
        action: @escaping AsyncBatchAction<Element, Element>,
        on database: Database,
        transaction: Bool = true,
        concurrently: Bool = true
    ) async throws -> [Element] {
        return try await database.performBatch(action: action,
                                               on: self,
                                               transaction: transaction,
                                               concurrently: concurrently)
    }
    
    /// Performs a custom batch operation that doesn't return a value.
    /// - Parameters:
    ///   - action: The custom operation to perform
    ///   - database: The database connection to perform the operations on
    ///   - transaction: When true, wraps operations in a transaction. Defaults to true
    ///   - concurrently: When true, processes operations concurrently. Defaults to true
    /// - Throws: Any database errors that occur during the operations
    func performBatchVoid(
        action: @escaping AsyncBatchAction<Element, Void>,
        on database: Database,
        transaction: Bool = true,
        concurrently: Bool = true
    ) async throws -> Void {
        try await database.performBatch(action: action,
                                               on: self,
                                               transaction: transaction,
                                               concurrently: concurrently)
    }
}
