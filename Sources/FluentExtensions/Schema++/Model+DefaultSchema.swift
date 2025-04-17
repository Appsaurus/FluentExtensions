//
//  Model+DefaultSchemaName.swift
//
//
//  Created by Brian Strobach on 8/30/21.
//

import Foundation
import Fluent

/// Extensions providing default schema name generation and schema builder access for Fluent models.
public extension Model {
    /// The default schema name for the model.
    ///
    /// By default, uses the string representation of the model type as the schema name.
    /// This is typically used as the database table name for the model.
    ///
    /// - Returns: A string representing the schema (table) name for this model.
    static var schema: String { "\(self)" }

    /// Creates a schema builder for this model on the specified database.
    ///
    /// This method provides convenient access to create or modify the database schema for this model.
    ///
    /// - Parameter database: The database instance to create the schema builder for.
    /// - Returns: A `SchemaBuilder` instance configured for this model's schema.
    static func schema(for database: Database) -> SchemaBuilder {
        database.schema(schema)
    }
}
