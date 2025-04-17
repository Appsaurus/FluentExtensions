//
//  Database+TransactionThrowing.swift
//
//
//  Created by Brian Strobach on 9/27/21.
//

import Fluent

/// Provides a throwing transaction wrapper around database operations that ensures proper error handling and transaction rollback.
public extension Database {
    /// Executes database operations within a transaction that automatically handles errors by propagating them up the call stack.
    /// This ensures that if any operation within the transaction throws an error, the entire transaction is rolled back.
    ///
    /// - Parameter closure: An async closure that performs database operations and may throw errors.
    /// - Returns: The result of type `T` from the successful transaction.
    /// - Throws: Any error that occurs during the transaction execution.
    ///
    /// ## Example Usage:
    /// ```swift
    /// try await database.transactionThrowing { db in
    ///     let user = try await User.find(id, on: db)
    ///     user.status = .active
    ///     try await user.save(on: db)
    /// }
    /// ```
    func transactionThrowing<T>(_ closure: @escaping (Database) async throws -> T) async throws -> T {
        try await transaction { database in
            do {
                return try await closure(database)
            } catch {
                throw error
            }
        }
    }
}
