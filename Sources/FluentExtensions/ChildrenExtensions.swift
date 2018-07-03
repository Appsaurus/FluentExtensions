//
//  ChildrenExtensions.swift
//  Servasaurus
//
//  Created by Brian Strobach on 12/18/17.
//

import Foundation
import Fluent

extension Children where Child: Model, Parent.Database: QuerySupporting{
	/// Returns true if the supplied model is a child
	/// to this relationship.
	public func includes(_ model: Child, on conn: DatabaseConnectable) throws -> Future<Bool> {
		return try query(on: conn)
			.filter(Child.idKey == model.requireID())
			.first()
			.map(to: Bool.self) { child in
				return child != nil
		}
	}
}

extension Model where Database: QuerySupporting{
	/// Returns true if this model is a child
	/// to the supplied relationship.
	public func isChild<M: Model>(_ children: Children<M, Self>, on conn: DatabaseConnectable) throws -> Future<Bool> {
		return try children.includes(self, on: conn)
	}
}
