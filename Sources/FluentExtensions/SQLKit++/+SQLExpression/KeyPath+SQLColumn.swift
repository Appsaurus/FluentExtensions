//
//  KeyPath+SQLColumn.swift
//
//
//  Created by Brian Strobach on 9/9/21.
//

import FluentSQL

/// Extensions for converting Schema KeyPaths to SQL expressions
public extension KeyPath where Root: Schema, Value: QueryableProperty {
    /// Converts the KeyPath to a SQLColumn representation
    var sqlColumn: SQLColumn {
        SQLColumn(self)
    }
    
    /// Returns the SQL table expression for the Schema type
    var sqlTable: SQLExpression {
        return Root.sqlTable
    }
}

/// Convenience initializer for creating SQLColumns from Schema KeyPaths
public extension SQLColumn {
    /// Creates a SQLColumn from a Schema KeyPath
    /// - Parameter keyPath: KeyPath pointing to a queryable property on a Schema
    init<M: Schema, V: QueryableProperty, KP: KeyPath<M,V>>(_ keyPath: KP)  {
        self.init(keyPath.propertyName, table: M.schemaOrAlias)
    }
}

/// Retroactively conform KeyPaths to SQLExpression when the Root is a Model and Value is QueryableProperty
///
/// This allows KeyPaths to be used directly in SQL expressions without explicit conversion
extension KeyPath:  /*@retroactive*/ SQLExpression where Root: Model, Value: QueryableProperty {
    /// Serializes the KeyPath as a SQL expression
    /// - Parameter serializer: The SQL serializer to write to
    public func serialize(to serializer: inout SQLSerializer) {
        SQLColumn(propertyName, table: Root.schemaOrAlias).serialize(to: &serializer)
    }
}
