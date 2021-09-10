//
//  ChildrenProperty++.swift
//
//
//  Created by Brian Strobach on 12/18/17.
//

import VaporExtensions
import Fluent

public extension ChildrenProperty {
	/// Returns true if the supplied model is a child
	/// to this relationship.
	func includes(_ model: To, on database: Database) -> Future<Bool> {
        do {
            let id = try model.requireID()
            return query(on: database)
                .filter(\._$id == id)
                .first()
                .map { child in
                    return child != nil
            }
        }
        catch {
            return database.eventLoop.fail(with: error)
        }

	}

    func all(on database: Database) -> Future<[To]> {
        return query(on: database).all()
    }
}

public extension Model {
	/// Returns true if this model is a child
	/// to the supplied relationship.
	func isChild<M: Model>(_ children: ChildrenProperty<M, Self>, on database: Database) -> Future<Bool> {
		return children.includes(self, on: database)
	}
}
