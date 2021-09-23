//
//  SQLAny.swift
//
//
//  Created by Brian Strobach on 9/23/21.
//

import SQLKit

extension SQLFunction {
    public static func any(_ expressions: [SQLExpression]) -> SQLFunction {
        return SQLFunction("ANY", args: expressions)
    }

    public static func any(_ expressions: SQLExpression...) -> SQLFunction {
        return SQLFunction("ANY", args: expressions)
    }
}

public func ANY(_ expression: SQLExpression...) -> SQLFunction {
    .any(expression)
}

public func ANY(_ expression: [SQLExpression]) -> SQLFunction {
    .any(expression)
}
