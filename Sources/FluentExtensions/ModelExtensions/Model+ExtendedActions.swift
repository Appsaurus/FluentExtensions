//
//  Model+ExtendedActions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 7/2/18.
//

import Foundation
import Fluent
import Vapor
import RuntimeExtensions

extension Future where T: Model{
	/// Performs an upsert with the given entity
	///
	/// - Returns: Bool indicating whether or not the object was created. True == created, False == updated
	@discardableResult
	public func upsert(on conn: DatabaseConnectable) throws -> Future<T>{
		return self.flatMap(to: T.self) { (model) in
			return try model.upsert(on: conn).transform(to: model)
		}
	}

	/// Overwrites the receiver with a replacement entity
	///
	/// - Parameter replacementEntity: The entity to be saved in place of the receiver.
	/// - Returns: The saved entity.
	@discardableResult
	public func replace(with replacementEntity: Future<T>, on conn: DatabaseConnectable) throws -> Future<T>{

		return flatMap(to: T.self){ model in
			return model.delete(on: conn).then{
				return replacementEntity.save(on: conn)
			}

		}
	}
}

extension Model where Database: QuerySupporting{

	/// Performs an upsert with the given entity
	///
	/// - Returns: Bool indicating whether or not the object was created. True == created, False == updated
	@discardableResult
	public func upsert(on conn: DatabaseConnectable) throws -> Future<Self>{
		return try existingEntityWithId(on: conn).flatMap(to: type(of: self)) { (model: Self?) in
			guard model == nil else {
				return self.save(on: conn)
			}
			return self.create(on: conn)
		}
	}

	public func replace(with model: Future<Self>, on conn: DatabaseConnectable) -> Future<Self> {
		return delete(on: conn).then({model.create(on: conn)})
	}

	public func updateIfExists(on conn: DatabaseConnectable) throws -> Future<Self>{
		return try assertExistingEntityWithId(on: conn).then({ future in
			return future.update(on: conn)
		})
	}
}
