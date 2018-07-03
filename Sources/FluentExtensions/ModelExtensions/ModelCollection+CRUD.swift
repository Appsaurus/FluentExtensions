//
//  Model+CollectionCRUD.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 7/2/18.
//

import Foundation
import Fluent
import Vapor

extension Collection where Element: Model{
	public func create(on conn: DatabaseConnectable) -> Future<[Element]>{
		return map { $0.create(on: conn) }.flatten(on: conn)
	}

	public func delete(on conn: DatabaseConnectable)  -> Future<Void>{
		return map { $0.delete(on: conn) }.flatten(on: conn)
	}

	public func save(on conn: DatabaseConnectable) -> Future<[Element]>{
		return map { $0.save(on: conn) }.flatten(on: conn)
	}

	public func update(on conn: DatabaseConnectable) throws -> Future<[Element]>{
		return map { $0.update(on: conn) }.flatten(on: conn)
	}
}

public typealias BatchAction<T> = (DatabaseConnectable) throws -> Future<T>

extension Collection where Element: Model, Element.Database: TransactionSupporting{

	public func performBatch<T>(action: @escaping BatchAction<T>, on conn: DatabaseConnectable, transaction: Bool) throws -> Future<T>{
		guard transaction else {
			return try action(conn)
		}
		return conn.transaction(on: try Element.requireDefaultDatabase(), { (conn) -> EventLoopFuture<T> in
			return try action(conn)
		})
	}

	public func create(on conn: DatabaseConnectable, transaction: Bool) throws -> Future<[Element]> {
		return try performBatch(action: create, on: conn, transaction: transaction)
	}

	public func delete(on conn: DatabaseConnectable, transaction: Bool) throws -> Future<Void> {
		return try performBatch(action: delete, on: conn, transaction: transaction)
	}

	public func save(on conn: DatabaseConnectable, transaction: Bool) throws -> Future<[Element]>{
		return try performBatch(action: save, on: conn, transaction: transaction)
	}

	public func update(on conn: DatabaseConnectable, transaction: Bool) throws -> Future<[Element]>{
		return try performBatch(action: update, on: conn, transaction: transaction)
	}
}


extension Future where T: Collection, T.Element: Model{

	public func create(on conn: DatabaseConnectable) -> Future<[T.Element]>{
		return flatMap(to: [T.Element].self) { elements in
			return elements.create(on: conn)
		}
	}

	public func delete(on conn: DatabaseConnectable) -> Future<Void>{
		return flatMap(to: Void.self) { elements in
			return elements.delete(on: conn)
		}
	}

	public func save(on conn: DatabaseConnectable) -> Future<[T.Element]>{
		return flatMap(to: [T.Element].self) { elements in
			return elements.save(on: conn)
		}
	}

	public func update(on conn: DatabaseConnectable) -> Future<[T.Element]>{
		return flatMap(to: [T.Element].self) { elements in
			return try elements.update(on: conn)
		}
	}
}

extension Future where T: Collection, T.Element: Model, T.Element.Database: TransactionSupporting{

	public func create(on conn: DatabaseConnectable, transaction: Bool) -> Future<[T.Element]>{
		return flatMap(to: [T.Element].self) { elements in
			return try elements.create(on: conn, transaction: transaction)
		}
	}

	public func delete(on conn: DatabaseConnectable, transaction: Bool) -> Future<Void>{
		return flatMap(to: Void.self) { elements in
			return try elements.delete(on: conn, transaction: transaction)
		}
	}

	public func save(on conn: DatabaseConnectable, transaction: Bool) -> Future<[T.Element]>{
		return flatMap(to: [T.Element].self) { elements in
			return try elements.save(on: conn, transaction: transaction)
		}
	}

	public func update(on conn: DatabaseConnectable, transaction: Bool) -> Future<[T.Element]>{
		return flatMap(to: [T.Element].self) { elements in
			return try elements.update(on: conn, transaction: transaction)
		}
	}
}
