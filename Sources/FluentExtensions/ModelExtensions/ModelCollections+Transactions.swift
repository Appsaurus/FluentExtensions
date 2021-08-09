//
//  File.swift
//  
//
//  Created by Brian Strobach on 8/9/21.
//

import FluentKit

public typealias BatchAction<V> = (Database) -> Future<V>
public typealias ThrowingBatchAction<V> = (Database) throws -> Future<V>

extension Collection where Element: Model {

    public func performBatch<V>(action: @escaping BatchAction<V>, on conn: Database, transaction: Bool) -> Future<V>{
        guard transaction else {
            return action(conn)
        }
        return conn.transaction { conn in
            return action(conn)
        }
    }
}


extension Future where Value: Collection, Value.Element: Model {
    public func performBatch<V>(action: @escaping BatchAction<V>, on conn: Database, transaction: Bool) -> Future<V>{
        return flatMap { elements in
            return elements.performBatch(action: action, on: conn, transaction: transaction)
        }
    }
}
