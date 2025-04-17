//
//  SQLAll.swift
//
//
//  Created by Brian Strobach on 9/23/21.
//

import SQLKit

extension SQLFunction {
    /// Creates an SQL ALL function that evaluates if all values in a set satisfy a condition.
    ///
    /// The ALL operator returns true if all values in a subquery or array meet a condition.
    /// Commonly used in WHERE clauses with comparison operators.
    ///
    /// ```swift
    /// // Example:
    /// // SELECT * FROM products WHERE price > ALL(SELECT price FROM discounted_products)
    /// queryBuilder.where("price", .greaterThan, SQLFunction.all([discountedPrices]))
    /// ```
    ///
    /// - Parameter expressions: An array of SQL expressions to evaluate.
    /// - Returns: An SQLFunction representing the ALL operation.
    public static func all(_ expressions: [SQLExpression]) -> SQLFunction {
        return SQLFunction("ALL", args: expressions)
    }

    /// Creates an SQL ALL function that evaluates if all values in a set satisfy a condition.
    ///
    /// Variadic parameter version of the array-based `all` function.
    ///
    /// - Parameter expressions: A variadic list of SQL expressions to evaluate.
    /// - Returns: An SQLFunction representing the ALL operation.
    public static func all(_ expressions: SQLExpression...) -> SQLFunction {
        return SQLFunction("ALL", args: expressions)
    }
}

/// Convenience function to create an ALL SQL function with variadic parameters.
///
/// - Parameter expression: A variadic list of SQL expressions to evaluate.
/// - Returns: An SQLFunction representing the ALL operation.
public func ALL(_ expression: SQLExpression...) -> SQLFunction {
    .all(expression)
}

/// Convenience function to create an ALL SQL function with an array of expressions.
///
/// - Parameter expression: An array of SQL expressions to evaluate.
/// - Returns: An SQLFunction representing the ALL operation.
public func ALL(_ expression: [SQLExpression]) -> SQLFunction {
    .all(expression)
}
