//
//  QueryParemeterFilter+NestedFilters.swift
//
//  Created by Brian Strobach on 2/13/25.
//

import Fluent

/// Extension providing static methods to create nested filter operations for Fluent queries
public extension QueryParameterFilter {
    /// Creates a filter for child relationships with an optional parent property
    /// - Parameter foreignKey: The optional parent property key path linking the parent to the child
    /// - Returns: A closure that builds a database filter for the child relationship
    static func Child<Parent: Model, Child: Model>(
        _ foreignKey: OptionalParentPropertyKeyPath<Parent, Child>
    ) -> (_ query: QueryBuilder<Parent>, _ field: String, _ condition: FilterCondition) throws -> DatabaseQuery.Filter? {
        { query, field, condition in
            query.join(Child.self, on: \Parent._$id == foreignKey.appending(path: \.$id))
            return try .build(from: condition, builder: .init(query, schema: Child.schemaOrAlias))
        }
    }
    
    /// Creates a filter for child relationships with a required parent property
    /// - Parameter foreignKey: The parent property key path linking the parent to the child
    /// - Returns: A closure that builds a database filter for the child relationship
    static func Child<Parent: Model, Child: Model>(
        _ foreignKey: ParentPropertyKeyPath<Parent, Child>
    ) -> (_ query: QueryBuilder<Parent>, _ field: String, _ condition: FilterCondition) throws -> DatabaseQuery.Filter? {
        { query, field, condition in
            query.join(Child.self, on: \Parent._$id == foreignKey.appending(path: \.$id))
            return try .build(from: condition, builder: .init(query, schema: Child.schemaOrAlias))
        }
    }
    
    /// Creates a filter for parent relationships with an optional parent property
    /// - Parameter foreignKey: The optional parent property key path linking the child to the parent
    /// - Returns: A closure that builds a database filter for the parent relationship
    static func Parent<Parent: Model, Child: Model>(
        _ foreignKey: OptionalParentPropertyKeyPath<Parent, Child>
    ) -> (_ query: QueryBuilder<Child>, _ field: String, _ condition: FilterCondition) throws -> DatabaseQuery.Filter? {
        { query, field, condition in
            query.join(parent: foreignKey)
            return try .build(from: condition, builder: .init(query, schema: Parent.schemaOrAlias))
        }
    }
    
    /// Creates a filter for parent relationships with a required parent property
    /// - Parameter foreignKey: The parent property key path linking the child to the parent
    /// - Returns: A closure that builds a database filter for the parent relationship
    static func Parent<Parent: Model, Child: Model>(
        _ foreignKey: ParentPropertyKeyPath<Parent, Child>
    ) -> (_ query: QueryBuilder<Child>, _ field: String, _ condition: FilterCondition) throws -> DatabaseQuery.Filter? {
        { query, field, condition in
            query.join(Parent.self, on: \Parent._$id == foreignKey.appending(path: \.$id))
            return try .build(from: condition, builder: .init(query, schema: Parent.schemaOrAlias))
        }
    }
    
    /// Creates a filter for many-to-many relationships using a pivot model
    /// - Parameter siblingsKey: The key path to the siblings property
    /// - Returns: A closure that builds a database filter for the siblings relationship
    static func Siblings<From: Model, To: Model, Through: Model>(
        _ siblingsKey: KeyPath<From, SiblingsProperty<From, To, Through>>
    ) -> (_ query: QueryBuilder<From>, _ field: String, _ condition: FilterCondition) throws -> DatabaseQuery.Filter? {
        { query, field, condition in
            query.join(siblings: siblingsKey)
            return try .build(from: condition, builder: .init(query, schema: To.schemaOrAlias))
        }
    }
}
