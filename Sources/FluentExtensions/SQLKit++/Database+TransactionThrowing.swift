//
//  Database+TransactionThrowing.swift
//  
//
//  Created by Brian Strobach on 9/27/21.
//

public extension Database {
    func transactionThrowing<T>(closure: @escaping (Database) throws -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return transaction { database in
            do {
                return try closure(database)
            }
            catch {
                return database.fail(with: error)
            }
        }
    }
}
