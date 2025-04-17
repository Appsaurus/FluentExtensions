//
//  KeyPathExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/22/18.
//

import Foundation
import FluentKit
import SQLKit

/// Extension providing database schema and query related functionality for KeyPaths that point to queryable properties in a Schema.
///
/// This extension enables easy access to database field information and query construction for properties
/// that conform to the `QueryableProperty` protocol within a `Schema` type.
public extension KeyPath where Root: Schema, Value: QueryableProperty {
    /// The dot-notation string representation of the property path.
    ///
    /// For nested properties, components are joined with dots. For example: "user.profile.name"
    var propertyName: String {
        return fieldKey.map({$0.description}).joined(separator: ".")
    }

    /// An array of coding keys representing the path to this property.
    ///
    /// Useful for encoding/decoding operations and creating type-safe database queries.
    var codingKeys: [CodingKeyRepresentable] {
        return fieldKey.map({$0.description})
    }

    /// The database field keys representing the path to this property.
    ///
    /// Returns an array of `FieldKey` that can be used to construct database queries
    /// and schema operations.
    var fieldKey: [FieldKey] {
        return Root.path(for: self)
    }

    /// A database query field representation of this property.
    ///
    /// Creates a `DatabaseQuery.Field` instance that includes both the field path
    /// and the schema (or alias) name, suitable for use in database queries.
    var databaseQueryField: DatabaseQuery.Field {
        .path(fieldKey, schema: Root.schemaOrAlias)
    }
}
