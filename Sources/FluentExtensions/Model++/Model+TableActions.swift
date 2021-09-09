//
//  Model+TableActions.swift
//  
//
//  Created by Brian Strobach on 9/2/21.
//

import Fluent

//MARK: Destructive
public extension Model {
    /// Deletes all rows in a table
    static func delete(force: Bool = false, on database: Database, transaction: Bool = true) -> Future<Void> {
        return query(on: database).all().delete(force: force, on: database, transaction: transaction)
    }
}
