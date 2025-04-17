//
//  SQLSum.swift
//
//
//  Created by Brian Strobach on 9/23/21.
//

import SQLKit

/// Extends ``SQLFunction`` to provide SQL SUM aggregation functionality.
public extension SQLFunction {
    /// Creates a SQL SUM function that computes the sum of values in a column.
    ///
    /// Use this to calculate the total of numeric values in a column when performing SQL queries.
    ///
    /// ```swift
    /// // Example:
    /// let totalRevenue = SQLFunction.sum(Column("revenue"))
    /// // Generates: SUM(revenue)
    /// ```
    ///
    /// - Parameter expression: The SQL expression to sum, typically a column reference
    /// - Returns: A ``SQLFunction`` representing the SUM operation
    static func sum(_ expression: SQLExpression) -> SQLFunction {
        return SQLFunction("SUM", args: expression)
    }
}

/// Convenience function to create a SQL SUM aggregation.
///
/// This global function provides a more concise syntax for creating SQL SUM operations.
///
/// ```swift
/// // These are equivalent:
/// let sum1 = SQLFunction.sum(Column("value"))
/// let sum2 = SUM(Column("value"))
/// ```
///
/// - Parameter expression: The SQL expression to sum
/// - Returns: A ``SQLFunction`` representing the SUM operation
public func SUM(_ expression: SQLExpression) -> SQLFunction {
    .sum(expression)
}
