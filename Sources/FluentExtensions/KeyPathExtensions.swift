//
//  KeyPathExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/22/18.
//

import Foundation
import FluentKit
public extension KeyPath where Root: Model, Value: QueryableProperty{
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
}
