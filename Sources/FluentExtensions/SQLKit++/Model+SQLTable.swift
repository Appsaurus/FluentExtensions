//
//  Model+SQLTable.swift
//
//
//  Created by Brian Strobach on 9/9/21.
//

import FluentSQL

public extension Model {
    static var sqlTable: SQLExpression {
        return schemaOrAlias
    }
}
