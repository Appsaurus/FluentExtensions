//
//  SQLSum.swift
//  
//
//  Created by Brian Strobach on 9/23/21.
//
import SQLKit

public extension SQLFunction {
    static func sum(_ expression: SQLExpression) -> SQLFunction {
        return SQLFunction("SUM", args: expression)
    }
}

public func SUM(_ expression: SQLExpression) -> SQLFunction {
    .sum(expression)
}



