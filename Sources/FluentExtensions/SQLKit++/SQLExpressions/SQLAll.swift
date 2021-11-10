//
//  SQLAll.swift
//
//
//  Created by Brian Strobach on 9/23/21.
//

import SQLKit

extension SQLFunction {
    public static func all(_ expressions: [SQLExpression]) -> SQLFunction {
        return SQLFunction("ALL", args: expressions)
    }

    public static func all(_ expressions: SQLExpression...) -> SQLFunction {
        return SQLFunction("ALL", args: expressions)
    }
}

public func ALL(_ expression: SQLExpression...) -> SQLFunction {
    .any(expression)
}

public func ALL(_ expression: [SQLExpression]) -> SQLFunction {
    .any(expression)
}
