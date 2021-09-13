//
//  KeyPathExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/22/18.
//

import Foundation
import FluentKit
import SQLKit


public extension KeyPath where Root: Schema, Value: QueryableProperty {
    var propertyName: String{
        return fieldKey.map({$0.description}).joined(separator: ".")
    }

    var codingKeys: [CodingKeyRepresentable] {
        return fieldKey.map({$0.description})
    }

	var fieldKey: [FieldKey]{
        return Root.path(for: self)
	}

    var databaseQueryField: DatabaseQuery.Field {
        .path(fieldKey, schema: Root.schemaOrAlias)
    }
}

