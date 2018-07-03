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
extension Model where Database: QuerySupporting{

	public func existingEntityWithId(on conn: DatabaseConnectable) throws -> Future<Self?>{
		guard let id = self.fluentID else {
			return Future.map(on: conn) { () -> Self? in
				return nil
			}
		}
		return Self.find(id, on: conn)
	}

	@discardableResult
	public func assertExistingEntityWithId(on conn: DatabaseConnectable) throws -> Future<Self>{
		return try existingEntityWithId(on: conn)
			.unwrap(or: Abort(.notFound, reason: "An entity with that ID could not be found."))
	}
}

extension Collection where Element: Model{

	@discardableResult
	public func assertExistingEntitiesWithIds(on conn: DatabaseConnectable) throws -> Future<[Element]>{
		var entities: [Future<Element>] = []
		for entity in self{
			entities.append(try entity.assertExistingEntityWithId(on: conn))
		}
		return entities.flatten(on: conn)
	}
}

//MARK: Destructive
extension Model where Database: QuerySupporting & TransactionSupporting{

	/// Deletes all rows in a table
	public static func delete(on conn: DatabaseConnectable, transaction: Bool = true) throws -> Future<Void> {
		return query(on: conn).all().delete(on: conn, transaction: transaction)
	}
}


//MARK: Query extensions

extension Model where Database: QuerySupporting{

	public static func find(_ ids: [Self.ID], on conn: DatabaseConnectable) -> Future<[Self]>{
		return query(on: conn).filter(idKey ~~ ids).all()

	}
	/// Attempts to find an instance of this model w/
	/// the supplied value at the given key path
	public static func find<V: Encodable>(_ keyPath: KeyPath<Self, V>, value: V, on conn: DatabaseConnectable) -> Future<Self?> {
		return query(on: conn).filter(keyPath == value).first()
	}
}

