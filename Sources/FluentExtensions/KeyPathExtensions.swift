//
//  KeyPathExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/22/18.
//

import Foundation
import Fluent
extension KeyPath where Root: Model{
	public func querySort(_ direction: Root.Database.QuerySortDirection = Root.Database.querySortDirectionAscending)-> Root.Database.QuerySort{
		return Root.Database.querySort(queryField, direction)
	}
	public var fluentProperty: FluentProperty{
		return .keyPath(self)
	}

	public var queryField: Root.Database.QueryField{
		return Root.Database.queryField(fluentProperty)
	}

	public var propertyName: String{
		return fluentProperty.name
	}
}
