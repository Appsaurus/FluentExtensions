//
//  EntityExtensions.swift
//  Servasaurus
//
//  Created by Brian Strobach on 11/30/17.
//

import Foundation
import Fluent
import Vapor
import RuntimeExtensions

//MARK: Existence checks
extension Model {

	public func existingEntityWithId(on database: Database) -> Future<Self?>{
		guard let id = self.id else {
            return database.eventLoop.makeSucceededFuture(nil)
		}
		return Self.find(id, on: database)
	}

	@discardableResult
	public func assertExistingEntityWithId(on database: Database) throws -> Future<Self>{
		return existingEntityWithId(on: database)
			.unwrap(or: Abort(.notFound, reason: "An entity with that ID could not be found."))
	}
}

extension Collection where Element: Model{

	@discardableResult
	public func assertExistingEntitiesWithIds(on database: Database) throws -> Future<[Element]>{
		var entities: [Future<Element>] = []
		for entity in self{
			entities.append(try entity.assertExistingEntityWithId(on: database))
		}
		return entities.flatten(on: database)
	}
}

//MARK: Destructive
extension Model {
	/// Deletes all rows in a table
	public static func delete(force: Bool = false, on database: Database, transaction: Bool = true) throws -> Future<Void> {
        return query(on: database).all().delete(force: force, on: database, transaction: transaction)
	}
}


//MARK: Query extensions

extension Model {

	public static func find(_ ids: [IDValue], on database: Database) -> Future<[Self]>{
		return query(on: database).filter(\._$id  ~~ ids).all()

	}
	/// Attempts to find an instance of this model w/
	/// the supplied value at the given key path
    public static func find<V: Encodable & QueryableProperty>(_ keyPath: KeyPath<Self, V>,
                                                              value: V.Value,
                                                              on database: Database) -> Future<Self?> {
        return query(on: database).filter(keyPath == value).first()
	}
}

