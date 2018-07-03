//
//  Model+CollectionExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 7/2/18.
//

import Foundation
import Fluent
import Vapor

extension Future where T: Collection, T.Element: Model{

	public func updateIfExists(on conn: DatabaseConnectable) throws -> Future<[T.Element]>{
		return flatMap(to: [T.Element].self) { elements in
			return try elements.updateIfExists(on: conn)
		}
	}

	public func replace(with models: Future<[T.Element]>, on conn: DatabaseConnectable) throws -> Future<[T.Element]>{
		return flatMap(to: [T.Element].self) { elements in
			return try elements.replace(with: models, on: conn)
		}
	}

	public func upsert(on conn: DatabaseConnectable) throws -> Future<[T.Element]>{
		return flatMap(to: [T.Element].self) { elements in
			return try elements.upsert(on: conn)
		}
	}
}
extension Collection where Element: Model{

	public func updateIfExists(on conn: DatabaseConnectable) throws -> Future<[Element]>{
		return try map { try $0.updateIfExists(on: conn) }.flatten(on: conn)
	}

	public func replace(with models: Future<[Element]>, on conn: DatabaseConnectable) throws -> Future<[Element]>{
		return map { $0.delete(on: conn) }
			.flatten(on: conn)
			.then({models.save(on: conn)})
	}

	public func upsert(on conn: DatabaseConnectable) throws -> Future<[Element]>{
		return try map { try $0.upsert(on: conn) }.flatten(on: conn)
	}
}

extension Collection where Element: Model, Element.Database: TransactionSupporting{

	public func updateIfExists(on conn: DatabaseConnectable, transaction: Bool) throws -> Future<[Element]>{
		return try performBatch(action: updateIfExists, on: conn, transaction: transaction)
	}

	public func upsert(on conn: DatabaseConnectable, transaction: Bool) throws -> Future<[Element]>{
		return try performBatch(action: upsert, on: conn, transaction: transaction)
	}
}


extension Future where T: Collection, T.Element: Model, T.Element.Database: TransactionSupporting{

	public func updateIfExists(on conn: DatabaseConnectable, transaction: Bool) -> Future<[T.Element]>{
		return flatMap(to: [T.Element].self) { elements in
			return try elements.updateIfExists(on: conn, transaction: transaction)
		}
	}
	
	public func upsert(on conn: DatabaseConnectable, transaction: Bool) -> Future<[T.Element]>{
		return flatMap(to: [T.Element].self) { elements in
			return try elements.upsert(on: conn, transaction: transaction)
		}
	}
}
