//
//  Model+TableActions.swift
//  
//
//  Created by Brian Strobach on 9/2/21.
//

import Fluent

//MARK: Destructive
extension Model {
    /// Deletes all rows in a table
    public static func delete(force: Bool = false, on database: Database, transaction: Bool = true) throws -> Future<Void> {
        return query(on: database).all().delete(force: force, on: database, transaction: transaction)
    }
}
