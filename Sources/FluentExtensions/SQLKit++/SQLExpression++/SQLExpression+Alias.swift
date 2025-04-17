//
//  SQLExpression+Alias.swift
//
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit

/// Extends ``SQLExpression`` to provide SQL aliasing functionality.
public extension SQLExpression {
    /// Creates a SQL alias for the current expression.
    ///
    /// Use this method to create readable aliases for SQL expressions, particularly useful in complex queries
    /// where referencing the original column or expression name might be ambiguous or verbose.
    ///
    /// ```swift
    /// // Example:
    /// let userCount = SQLFunction("COUNT", args: [SQLIdentifier("id")]).as("total_users")
    /// // Produces: COUNT(id) AS total_users
    /// ```
    ///
    /// - Parameter alias: The alias name to assign to the expression
    /// - Returns: A ``SQLAlias`` representing the aliased expression
    func `as`(_ alias: String) -> SQLAlias {
        SQLAlias(self, as: SQLIdentifier(alias))
    }
}
