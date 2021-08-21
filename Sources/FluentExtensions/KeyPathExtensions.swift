//
//  KeyPathExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/22/18.
//

import Foundation
import FluentKit
extension KeyPath where Root: Model, Value: QueryableProperty{
//	public func querySort(_ direction: Root.Database.QuerySortDirection = Root.Database.querySortDirectionAscending)-> Root.Database.QuerySort{
//		return Root.Database.querySort(queryField, direction)
//	}
	public var fluentProperty: [FieldKey]{        
        return Root.path(for: self)
	}
//
//	public var queryField: Root.Database.QueryField{
//		return Root.Database.queryField(fluentProperty)
//	}

	public var propertyName: String{
        return fluentProperty.map({$0.description}).joined(separator: ".")
	}
}
