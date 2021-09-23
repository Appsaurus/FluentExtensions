//
//  Schema+SQLTable.swift
//
//
//  Created by Brian Strobach on 9/9/21.
//

import FluentSQL

public extension Schema {
    static var sqlTable: SQLIdentifier {
        return SQLIdentifier(schema)
    }
}
