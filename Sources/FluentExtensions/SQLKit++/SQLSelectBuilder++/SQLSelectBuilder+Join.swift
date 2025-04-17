//
//  SQLSelectBuilder+Join.swift
//
//
//  Created by Brian Strobach on 10/26/21.
//

import SQLKit

/// Extends ``SQLSelectBuilder`` to provide type-safe SQL JOIN operations using Swift KeyPaths.
public extension SQLSelectBuilder {
    /// Performs a JOIN operation between two model tables using their KeyPath properties.
    ///
    /// This method enables type-safe JOIN operations between Fluent models by leveraging Swift's KeyPath type system.
    /// It automatically constructs the JOIN clause using the provided KeyPaths and their corresponding model tables.
    ///
    /// Example:
    /// ```swift
    /// // Joining User and Post models on user.id = post.userId
    /// query.join(\Post.userId, to: \User.$id)
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: KeyPath to the local model's property that will be used in the JOIN condition
    ///   - rhs: KeyPath to the foreign model's property that will be matched in the JOIN condition
    /// - Returns: The modified SQLSelectBuilder instance for method chaining
    func join<Foreign, ForeignField, Local, LocalField>(
        _ lhs: KeyPath<Local, LocalField>, to rhs: KeyPath<Foreign, ForeignField>
    ) -> Self
        where
            ForeignField: QueryableProperty,
            ForeignField.Model == Foreign,
            LocalField: QueryableProperty,
            LocalField.Model == Local,
            ForeignField.Value == LocalField.Value,
            Local: Model,
            Foreign: Model {
        return self.join(Foreign.sqlTable, on: lhs, .equal, rhs)
    }
}
