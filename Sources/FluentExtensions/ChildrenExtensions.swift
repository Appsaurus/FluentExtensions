//
//  ChildrenExtensions.swift
//  Servasaurus
//
//  Created by Brian Strobach on 12/18/17.
//

import Foundation
import Fluent

extension ChildrenProperty {
	/// Returns true if the supplied model is a child
	/// to this relationship.
	public func includes(_ model: To, on database: Database) throws -> Future<Bool> {
        let id = try model.requireID()
		return query(on: database)
			.filter(\._$id == id)
			.first()
			.map { child in
				return child != nil
		}
	}
}

extension Model {
	/// Returns true if this model is a child
	/// to the supplied relationship.
	public func isChild<M: Model>(_ children: ChildrenProperty<M, Self>, on database: Database) throws -> Future<Bool> {
		return try children.includes(self, on: database)
	}
}
