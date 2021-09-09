//
//  KeyPathExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/22/18.
//

import Foundation
import FluentKit
import SQLKit

public extension Model {
    static var sqlTable: SQLExpression {
        return SQLLiteral.string(schemaOrAlias)
    }
}
public extension KeyPath where Root: Model, Value: QueryableProperty {
//	func querySort(_ direction: Root.Database.QuerySortDirection = Root.Database.querySortDirectionAscending)-> Root.Database.QuerySort{
//		return Root.Database.querySort(queryField, direction)
//	}
	var fieldKey: [FieldKey]{
        return Root.path(for: self)
	}

    var databaseQueryField: DatabaseQuery.Field {
        .path(fieldKey, schema: Root.schemaOrAlias)
    }

	var propertyName: String{
        return fieldKey.map({$0.description}).joined(separator: ".")
	}

    var codingKeys: [CodingKeyRepresentable] {
        return fieldKey.map({$0.description})
    }

    var sqlColumn: SQLColumn {
        SQLColumn(self)
    }

    var sqlTable: SQLExpression {
        return Root.sqlTable
    }
}

extension SQLColumn {
    public init<M: Model, V: QueryableProperty, KP: KeyPath<M,V>>(_ keyPath: KP)  {
        self.init(keyPath.propertyName, table: M.schemaOrAlias)
    }
}
extension KeyPath: SQLExpression where Root: Model, Value: QueryableProperty {

    public func serialize(to serializer: inout SQLSerializer) {
        SQLColumn(propertyName, table: Root.schemaOrAlias).serialize(to: &serializer)
    }
}
