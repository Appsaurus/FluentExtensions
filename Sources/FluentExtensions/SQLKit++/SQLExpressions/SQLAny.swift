//
//  SQLAny.swift
//
//
//  Created by Brian Strobach on 9/23/21.
//

import SQLKit

/// Extends `SQLFunction` to provide SQL ANY operator functionality.
extension SQLFunction {
    /// Creates a SQL ANY function that tests whether a value matches any value in a set.
    ///
    /// - Parameter expressions: An array of SQL expressions to match against.
    /// - Returns: A `SQLFunction` representing the ANY operation.
    ///
    /// - Example:
    /// ```swift
    /// // SELECT * FROM users WHERE age = ANY(SELECT age FROM special_users)
    /// query.where("age", .equal, SQLFunction.any(subquery))
    /// ```
    public static func any(_ expressions: [SQLExpression]) -> SQLFunction {
        return SQLFunction("ANY", args: expressions)
    }

    /// Creates a SQL ANY function that tests whether a value matches any value in a set.
    ///
    /// - Parameter expressions: A variadic list of SQL expressions to match against.
    /// - Returns: A `SQLFunction` representing the ANY operation.
    public static func any(_ expressions: SQLExpression...) -> SQLFunction {
        return SQLFunction("ANY", args: expressions)
    }
}

/// Global function to create a SQL ANY expression with variadic parameters.
///
/// - Parameter expression: A variadic list of SQL expressions to match against.
/// - Returns: A `SQLFunction` representing the ANY operation.
public func ANY(_ expression: SQLExpression...) -> SQLFunction {
    .any(expression)
}

/// Global function to create a SQL ANY expression with an array of expressions.
///
/// - Parameter expression: An array of SQL expressions to match against.
/// - Returns: A `SQLFunction` representing the ANY operation.
public func ANY(_ expression: [SQLExpression]) -> SQLFunction {
    .any(expression)
}
