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

	public func existingEntityWithId(on conn: Database) -> Future<Self?>{
		guard let id = self.id else {
            return conn.eventLoop.makeSucceededFuture(nil)
		}
		return Self.find(id, on: conn)
	}

	@discardableResult
	public func assertExistingEntityWithId(on conn: Database) throws -> Future<Self>{
		return existingEntityWithId(on: conn)
			.unwrap(or: Abort(.notFound, reason: "An entity with that ID could not be found."))
	}
}

extension Collection where Element: Model{

	@discardableResult
	public func assertExistingEntitiesWithIds(on conn: Database) throws -> Future<[Element]>{
		var entities: [Future<Element>] = []
		for entity in self{
			entities.append(try entity.assertExistingEntityWithId(on: conn))
		}
		return entities.flatten(on: conn)
	}
}

//MARK: Destructive
extension Model {
	/// Deletes all rows in a table
	public static func delete(force: Bool = false, on conn: Database, transaction: Bool = true) throws -> Future<Void> {
        return query(on: conn).all().delete(force: force, on: conn, transaction: transaction)
	}
}


//MARK: Query extensions

extension Model {

	public static func find(_ ids: [IDValue], on conn: Database) -> Future<[Self]>{
		return query(on: conn).filter(\._$id  ~~ ids).all()

	}
	/// Attempts to find an instance of this model w/
	/// the supplied value at the given key path
    public static func find<V: Encodable & QueryableProperty>(_ keyPath: KeyPath<Self, V>,
                                                              value: V.Value,
                                                              on conn: Database) -> Future<Self?> {
        return query(on: conn).filter(keyPath == value).first()
	}
}

