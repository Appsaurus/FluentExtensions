//
//  QueryParemeterFilter+NestedFilters.swift
//
//
//  Created by Brian Strobach on 2/13/25.
//

import Fluent

public extension QueryParameterFilter {
    static func Child<Parent: Model, Child: Model>(
        _ foreignKey: OptionalParentPropertyKeyPath<Parent, Child>
    ) -> (_ query: QueryBuilder<Parent>, _ field: String, _ condition: FilterCondition) throws -> DatabaseQuery.Filter? {
        { query, field, condition in
            query.join(Child.self, on: \Parent._$id == foreignKey.appending(path: \.$id))
            return try .build(from: condition, builder: .init(query, schema: Child.schemaOrAlias))
        }
    }
    
    static func Child<Parent: Model, Child: Model>(
        _ foreignKey: ParentPropertyKeyPath<Parent, Child>
    ) -> (_ query: QueryBuilder<Parent>, _ field: String, _ condition: FilterCondition) throws -> DatabaseQuery.Filter? {
        { query, field, condition in
            query.join(Child.self, on: \Parent._$id == foreignKey.appending(path: \.$id))
            return try .build(from: condition, builder: .init(query, schema: Child.schemaOrAlias))
        }
    }
    
    static func Parent<Parent: Model, Child: Model>(
        _ foreignKey: OptionalParentPropertyKeyPath<Parent, Child>
    ) -> (_ query: QueryBuilder<Child>, _ field: String, _ condition: FilterCondition) throws -> DatabaseQuery.Filter? {
        { query, field, condition in
            query.join(parent: foreignKey)
            return try .build(from: condition, builder: .init(query, schema: Parent.schemaOrAlias))
        }
    }
    
    static func Parent<Parent: Model, Child: Model>(
        _ foreignKey: ParentPropertyKeyPath<Parent, Child>
    ) -> (_ query: QueryBuilder<Child>, _ field: String, _ condition: FilterCondition) throws -> DatabaseQuery.Filter? {
        { query, field, condition in
            query.join(Parent.self, on: \Parent._$id == foreignKey.appending(path: \.$id))
            return try .build(from: condition, builder: .init(query, schema: Parent.schemaOrAlias))
        }
    }
    
    static func Siblings<From: Model, To: Model, Through: Model>(
        _ siblingsKey: KeyPath<From, SiblingsProperty<From, To, Through>>
    ) -> (_ query: QueryBuilder<From>, _ field: String, _ condition: FilterCondition) throws -> DatabaseQuery.Filter? {
        { query, field, condition in
            query.join(siblings: siblingsKey)
            return try .build(from: condition, builder: .init(query, schema: To.schemaOrAlias))
        }
    }
}
