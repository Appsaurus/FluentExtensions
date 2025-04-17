//
//  Schema+SQLTable.swift
//
//
//  Created by Brian Strobach on 9/9/21.
//

import FluentSQL

/// Extensions for converting Fluent Schema names to SQLKit identifiers.
public extension Schema {
    /// Converts the schema name to a ``SQLIdentifier``.
    ///
    /// This property provides a convenient way to access the schema name as a SQL identifier,
    /// which is useful when constructing raw SQL queries or working with SQLKit directly.
    ///
    /// ```swift
    /// let tableName = MyModel.schema.sqlTable
    /// // Use tableName in SQL queries
    /// ```
    ///
    /// - Returns: A ``SQLIdentifier`` representing the schema name.
    static var sqlTable: SQLIdentifier {
        return SQLIdentifier(schema)
    }
}
