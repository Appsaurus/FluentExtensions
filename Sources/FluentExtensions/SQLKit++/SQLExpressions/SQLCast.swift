//
//  SQLCast.swift
//
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit

/// A SQL expression that represents a CAST operation to convert data from one type to another.
///
/// Use SQLCast to explicitly convert a SQL expression to a different data type during a query.
/// This is particularly useful when:
/// - You need to ensure type compatibility in comparisons
/// - Converting string representations to dates or numbers
/// - Ensuring consistent data types across different database systems
///
/// Example:
/// ```swift
/// // Cast a string column to an integer
/// let query = db.select()
///     .column(CAST(Column("string_id"), as: .integer))
///     .from("users")
/// ```
public struct SQLCast: SQLExpression {
    /// The expression to be cast to a new type
    public var expression: SQLExpression
    
    /// The target SQL data type for the cast operation
    public var type: SQLDataType

    /// Creates a new CAST expression.
    /// - Parameters:
    ///   - expression: The SQL expression to cast
    ///   - type: The target SQL data type
    public init(_ expression: SQLExpression, as type: SQLDataType) {
        self.expression = expression
        self.type = type
    }

    /// Serializes the CAST expression into SQL syntax.
    ///
    /// The resulting SQL will be in the format: `CAST(expression AS type)`
    public func serialize(to serializer: inout SQLSerializer) {
        serializer.write("CAST(")
        self.expression.serialize(to: &serializer)
        serializer.write(" AS ")
        self.type.serialize(to: &serializer)
        serializer.write(")")
    }
}

// MARK: - SQLExpression Extensions
public extension SQLExpression {
    /// Casts the current expression to a specified SQL data type.
    /// - Parameter type: The target SQL data type
    /// - Returns: A new SQLCast expression
    func cast(as type: SQLDataType) -> SQLCast {
        SQLCast(self, as: type)
    }
}

/// Creates a CAST expression using function-like syntax.
/// - Parameters:
///   - expression: The SQL expression to cast
///   - type: The target SQL data type
/// - Returns: A new SQLCast expression
public func CAST(_ expression: SQLExpression, as type: SQLDataType) -> SQLCast {
    SQLCast(expression, as: type)
}
