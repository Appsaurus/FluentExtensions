//
//  SQLCount.swift
//
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit

extension SQLFunction {
    /// Creates a SQL COUNT function expression.
    /// - Parameter expressions: Array of expressions to count. Defaults to `[SQLLiteral.all]` which translates to `COUNT(*)`.
    /// - Returns: A `SQLFunction` representing the COUNT operation.
    ///
    /// Example:
    /// ```swift
    /// // COUNT(*)
    /// let countAll = SQLFunction.count()
    /// // COUNT(column_name)
    /// let countColumn = SQLFunction.count(SQLIdentifier("column_name"))
    /// ```
    public static func count(_ expressions: [SQLExpression] = [SQLLiteral.all]) -> SQLFunction {
        return SQLFunction("COUNT", args: expressions)
    }

    /// Creates a SQL COUNT function expression with variadic parameters.
    /// - Parameter expressions: Variadic list of expressions to count.
    /// - Returns: A `SQLFunction` representing the COUNT operation.
    public static func count(_ expressions: SQLExpression...) -> SQLFunction {
        return SQLFunction("COUNT", args: expressions)
    }
}

/// Global function for creating SQL COUNT expressions.
/// - Parameter expression: Variadic list of expressions to count.
/// - Returns: A `SQLFunction` representing the COUNT operation.
public func COUNT(_ expression: SQLExpression...) -> SQLFunction {
    .count(expression)
}

/// Global function for creating SQL COUNT expressions.
/// - Parameter expression: Array of expressions to count. Defaults to `[SQLLiteral.all]`.
/// - Returns: A `SQLFunction` representing the COUNT operation.
public func COUNT(_ expression: [SQLExpression] = [SQLLiteral.all]) -> SQLFunction {
    .count(expression)
}
