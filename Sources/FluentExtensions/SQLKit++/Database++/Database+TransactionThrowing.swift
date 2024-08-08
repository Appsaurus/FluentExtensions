//
//  Database+TransactionThrowing.swift
//
//
//  Created by Brian Strobach on 9/27/21.
//

import Fluent

public extension Database {
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
