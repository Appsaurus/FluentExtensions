//
//  SQLUnion.swift
//
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit

/// A SQL UNION expression that combines the results of two or more SELECT statements.
///
/// Use SQLUnion to merge multiple result sets into a single result set that includes all the rows that belong to all the SELECT statements in the union.
/// Each SELECT statement within the union must have the same number of columns, and the columns must have compatible data types.
///
/// Example:
/// ```swift
/// let union = UNION(
///     SQLSelect().column("id").from("users"),
///     SQLSelect().column("id").from("admins")
/// )
/// ```
public struct SQLUnion: SQLExpression {
    /// The SQL expressions to be combined with UNION.
    public let args: [SQLExpression]

    /// Creates a new SQLUnion expression with the provided SQL expressions.
    /// - Parameter args: The SQL expressions to union together.
    public init(_ args: SQLExpression...) {
        self.init(args)
    }

    /// Creates a new SQLUnion expression with an array of SQL expressions.
    /// - Parameter args: An array of SQL expressions to union together.
    public init(_ args: [SQLExpression]) {
        self.args = args
    }

    /// Serializes the UNION expression to the SQL serializer.
    /// - Parameter serializer: The SQL serializer to write the expression to.
    public func serialize(to serializer: inout SQLSerializer) {
        let args = args.map(SQLGroupExpression.init)
        guard let first = args.first else { return }
        first.serialize(to: &serializer)
        for arg in args.dropFirst() {
            serializer.write(" UNION ")
            arg.serialize(to: &serializer)
        }
    }
}

/// Creates a SQLUnion expression from an array of SQL expressions.
/// - Parameter args: An array of SQL expressions to union together.
/// - Returns: A SQLUnion expression combining all provided expressions.
public func UNION(_ args: [SQLExpression]) -> SQLUnion {
    SQLUnion(args)
}

/// Creates a SQLUnion expression from a variadic list of SQL expressions.
/// - Parameter args: The SQL expressions to union together.
/// - Returns: A SQLUnion expression combining all provided expressions.
public func UNION(_ args: SQLExpression...) -> SQLUnion {
    SQLUnion(args)
}
