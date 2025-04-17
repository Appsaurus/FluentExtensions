//
//  SQLPredicateBuilder++.swift
//
//
//  Created by Brian Strobach on 10/25/21.
//

import SQLKit

/// Extends SQLPredicateBuilder to provide a convenient way to create WHERE clauses with Encodable values.
public extension SQLPredicateBuilder {
    /// Adds a WHERE clause to the SQL query comparing a column expression against an encodable value.
    ///
    /// This method automatically binds the provided value to prevent SQL injection and handles proper value encoding.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side SQL expression (typically a column reference)
    ///   - op: The binary operator to use for comparison (e.g., ==, >, <, etc.)
    ///   - rhs: The right-hand side value to compare against, which will be automatically encoded
    ///
    /// - Returns: Self for method chaining
    ///
    /// - Example:
    ///   ```swift
    ///   builder.where("age", .greaterThan, 21)
    ///   // Generates: WHERE "age" > $1
    ///   ```
    @discardableResult
    func `where`<E>(_ lhs: SQLExpression, _ op: SQLBinaryOperator, _ rhs: E) -> Self
        where E: Encodable
    {
        return self.where(lhs, op, SQLBind(rhs))
    }
}
