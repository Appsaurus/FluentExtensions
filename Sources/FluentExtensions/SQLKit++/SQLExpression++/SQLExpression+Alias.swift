//
//  SQLExpression+Alias.swift
//  
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit

public extension SQLExpression {
    func `as`(_ alias: String) -> SQLAlias {
        SQLAlias(self, as: SQLIdentifier(alias))
    }
}
