//
//  File.swift
//  
//
//  Created by Brian Strobach on 8/9/21.
//

import FluentKit

public typealias BatchAction<V> = (Database) -> Future<V>
public typealias ThrowingBatchAction<V> = (Database) throws -> Future<V>

public extension Collection where Element: Model {

    func performBatch<V>(action: @escaping BatchAction<V>, on database: Database, transaction: Bool) -> Future<V>{
        guard transaction else {
            return action(database)
        }
        return database.transaction { conn in
            return action(conn)
        }
    }
}


public extension Future where Value: Collection, Value.Element: Model {
    func performBatch<V>(action: @escaping BatchAction<V>, on database: Database, transaction: Bool) -> Future<V>{
        return flatMap { elements in
            return elements.performBatch(action: action, on: database, transaction: transaction)
        }
    }
}
