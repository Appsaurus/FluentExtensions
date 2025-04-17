//
//  SchemaBuilder+IDSugar.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/27/18.
//

import Foundation
import Vapor
import Fluent

/// Extends `SchemaBuilder` to provide convenient methods for adding ID fields to database schemas.
public extension SchemaBuilder {
    
    /// Adds an auto-incrementing integer ID field to the schema.
    ///
    /// This method creates a field named "id" of type `Int` that serves as the primary identifier
    /// for the database table.
    ///
    /// - Parameter auto: Whether the ID should auto-increment. Defaults to `true`.
    /// - Returns: The schema builder for further configuration.
    func intID(auto: Bool = true) -> Self {
        field(.id, .int, .identifier(auto: auto))
    }

    /// Adds a string ID field to the schema.
    ///
    /// This method creates a field named "id" of type `String` that serves as the primary identifier
    /// for the database table. Useful for UUID strings or custom ID formats.
    ///
    /// - Parameter auto: Whether the ID should auto-generate. Defaults to `true`.
    /// - Returns: The schema builder for further configuration.
    func stringID(auto: Bool = true) -> Self {
        field(.id, .string, .identifier(auto: auto))
    }
}
