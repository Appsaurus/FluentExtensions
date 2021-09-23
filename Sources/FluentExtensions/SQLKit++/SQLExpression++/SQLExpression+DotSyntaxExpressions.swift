//
//  SQLExpression+DotSyntaxExpressions.swift
//  
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit

public extension SQLExpression {
    func `as`(_ alias: SQLExpression) -> SQLAlias {
        SQLAlias(self, as: alias)
    }

    func identifier(_ string: String) -> SQLIdentifier {
        SQLIdentifier(string)
    }
}

public func coalesce(_ expressions: SQLExpression...) -> SQLFunction {
    .coalesce(expressions)
}
