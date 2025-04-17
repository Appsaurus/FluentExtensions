//
//  SQLCase.swift
//
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit

/// A type that represents a SQL CASE statement expression.
///
/// Use `SQLCase` to construct SQL CASE WHEN statements for conditional logic in your SQL queries.
/// This allows for branching logic directly in your SQL statements.
///
/// Example:
/// ```swift
/// // Simple CASE WHEN statement
/// let case = SQLCase(when: [(age > 18, "Adult"), (age > 12, "Teen")], else: "Child")
///
/// // Complex nested conditions
/// let case = SQLCase(when: [
///     (SQLBinary(.and, left: age > 18, right: salary > 50000), "High earning adult"),
///     (age > 18, "Adult"),
///     (age > 12, "Teen")
/// ], else: "Child")
/// ```
public struct SQLCase: SQLExpression {
    /// Array of condition-predicate pairs representing WHEN/THEN clauses
    public var cases: [(condition: SQLExpression, predicate: SQLExpression)]
    
    /// Optional ELSE clause expression
    public var alternative: SQLExpression?

    /// Creates a new CASE statement with multiple conditions and an optional else clause.
    /// - Parameters:
    ///   - cases: Array of tuples containing condition-predicate pairs
    ///   - else: Optional alternative expression for when no conditions match
    public init(when cases: [(SQLExpression, SQLExpression)], `else`: SQLExpression? = nil) {
        self.cases = cases
        self.alternative = `else`
    }
    
    /// Creates a new CASE statement with variadic conditions and an optional else clause.
    /// - Parameters:
    ///   - cases: Variadic tuples containing condition-predicate pairs
    ///   - else: Optional alternative expression for when no conditions match
    public init(when cases: (SQLExpression, SQLExpression)..., `else`: SQLExpression? = nil) {
        self.cases = cases
        self.alternative = `else`
    }
    
    /// Serializes the CASE statement into SQL syntax
    public func serialize(to serializer: inout SQLSerializer) {
        serializer.write("CASE")
        cases.forEach {
            serializer.write(" WHEN ")
            $0.condition.serialize(to: &serializer)
            serializer.write(" THEN ")
            $0.predicate.serialize(to: &serializer)
        }
        alternative.map {
            serializer.write(" ELSE ")
            $0.serialize(to: &serializer)
        }
        serializer.write(" END")
    }
}

/// Convenient extensions for creating CASE expressions from any SQLExpression
public extension SQLExpression {
    /// Creates a CASE statement with multiple conditions and an optional else clause.
    /// - Parameters:
    ///   - cases: Array of tuples containing condition-predicate pairs
    ///   - ELSE: Optional alternative expression for when no conditions match
    /// - Returns: A new SQLCase expression
    func `CASE`(WHEN cases: [(condition: SQLExpression, THEN: SQLExpression)], `ELSE`: SQLExpression? = nil) -> SQLCase {
        return SQLCase(when: cases, else: ELSE)
    }
    
    /// Creates a CASE statement with variadic conditions and an optional else clause.
    /// - Parameters:
    ///   - cases: Variadic tuples containing condition-predicate pairs
    ///   - ELSE: Optional alternative expression for when no conditions match
    /// - Returns: A new SQLCase expression
    func `CASE`(WHEN cases: (condition: SQLExpression, THEN: SQLExpression)..., `ELSE`: SQLExpression? = nil) -> SQLCase {
        return SQLCase(when: cases, else: ELSE)
    }
}
