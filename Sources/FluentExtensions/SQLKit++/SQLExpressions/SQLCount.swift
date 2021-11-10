//
//  SQLCount.swift
//  
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit

extension SQLFunction {
    public static func count(_ expressions: [SQLExpression] = [SQLLiteral.all]) -> SQLFunction {
        return SQLFunction("COUNT", args: expressions)
    }

    public static func count(_ expressions: SQLExpression...) -> SQLFunction {
        return SQLFunction("COUNT", args: expressions)
    }
}

public func COUNT(_ expression: SQLExpression...) -> SQLFunction {
    .count(expression)
}

public func COUNT(_ expression: [SQLExpression] = [SQLLiteral.all]) -> SQLFunction {
    .count(expression)
}


