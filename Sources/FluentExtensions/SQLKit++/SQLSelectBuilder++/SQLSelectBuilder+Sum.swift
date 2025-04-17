//
//  SQLSelectBuilder+Sum.swift
//
//
//  Created by Brian Strobach on 9/23/21.
//

import SQLKit
import Fluent

/// Extends ``SQLSelectBuilder`` with sum computation capabilities.
public extension SQLSelectBuilder {
    /// Adds a SQL SUM function to the select statement with optional type casting and custom labeling.
    ///
    /// - Parameters:
    ///   - expression: The ``SQLExpression`` to sum
    ///   - castedType: Optional ``SQLDataType`` to cast the sum result to a specific type
    ///   - label: The column label for the sum result in the query output
    /// - Returns: Modified ``SQLSelectBuilder`` with the sum expression added
    func sum(_ expression: SQLExpression, as castedType: SQLDataType? = nil, labeled label: String) -> SQLSelectBuilder {
        var function: SQLExpression = SQLFunction.sum(expression)
        if let cast = castedType {
            function = function.cast(as: cast)
        }
        return column(function.as(label))
    }

    /// Computes the sum of a model's field values using a type-safe KeyPath.
    ///
    /// This method provides a type-safe way to sum values from a specific model field.
    /// The result is automatically decoded into the field's value type.
    ///
    /// Example:
    /// ```swift
    /// // Sum all user balances
    /// let totalBalance = try await db.select()
    ///     .sum(\User.$balance)
    ///     .from(User.self)
    /// ```
    ///
    /// - Parameter key: KeyPath to the field to sum
    /// - Returns: The sum of all values for the specified field, or nil if no rows match
    /// - Throws: Any database errors that occur during query execution
    func sum<M: Model, Field>(_ key: KeyPath<M, Field>) async throws -> Field.Value?
        where
            Field: QueryableProperty,
            Field.Model == M
    {
        let values = try await self.sum(key, labeled: "sum")
            .from(M.sqlTable)
            .all(decoding: SumRow<Field.Value>.self)
        
        return values.first?.sum
    }
}

/// A decodable container for sum query results.
public struct SumRow<Value: Codable>: Codable {
    /// The computed sum value
    public var sum: Value
}
