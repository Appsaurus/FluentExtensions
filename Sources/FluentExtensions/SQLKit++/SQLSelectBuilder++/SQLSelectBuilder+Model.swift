//
//  SQLSelectBuilder+Model.swift
//
//
//  Created by Brian Strobach on 9/23/21.
//

import SQLKit
import Fluent

/// Provides Fluent Model integration for SQL SELECT queries.
public extension SQLSelectBuilder {
    /// Creates a SELECT query targeting a Fluent Model's database table.
    ///
    /// Use this method to construct SELECT queries that target a specific model's table
    /// without having to manually specify the table name.
    ///
    /// ```swift
    /// // Example:
    /// database.select()
    ///     .from(User.self)
    ///     .where("age", .greaterThan, 18)
    /// ```
    ///
    /// - Parameter modelType: The Fluent Model type whose table should be queried
    /// - Returns: Self for method chaining
    func from<M: Model>(_ modelType: M.Type) -> Self {
        return from(modelType.sqlTable)
    }
}
