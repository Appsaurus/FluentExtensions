//
//  Model+CollectionExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 7/2/18.
//

import Foundation
import Fluent
import Vapor


extension Collection where Element: Model{
    public func save(on database: Database) -> EventLoopFuture<Void> {
        guard self.count > 0 else {
            return database.eventLoop.makeSucceededFuture(())
        }

        return compactMap({$0.save(on: database)}).flatten(on: database.eventLoop)
    }

    public func update(on database: Database) -> EventLoopFuture<Void> {
        guard self.count > 0 else {
            return database.eventLoop.makeSucceededFuture(())
        }

        self.forEach { model in
            precondition(!model._$id.exists)
        }

        return compactMap({$0.update(on: database)}).flatten(on: database.eventLoop)
    }

}


public extension Collection where Element: Model{
    func upsert(on conn: Database) -> Future<Void>{
        compactMap { $0.upsert(on: conn) }.flatten(on: conn.eventLoop).flattenVoid()
    }
    func updateIfExists(on conn: Database) throws -> Future<Void>{
        try compactMap { try $0.updateIfExists(on: conn) }.flatten(on: conn.eventLoop).flattenVoid()
    }


    func upsert(on conn: Database, transaction: Bool) -> Future<Void>{
        return performBatch(action: upsert, on: conn, transaction: transaction)
    }

    func replace(with models: Future<Self>, on conn: Database, transaction: Bool) -> Future<Void>{
         map { return $0.delete(on: conn) }
            .compactMap{ _ in
                models.save(on: conn, transaction: transaction)
            }.flatten(on: conn.eventLoop)
    }
}

public extension Future where Value: Collection, Value.Element: Model{
    func upsert(on conn: Database, transaction: Bool) -> Future<Void>{
         flatMap { $0.upsert(on: conn, transaction: transaction) }
    }


    func replace(with models: Future<Value>, on conn: Database, transaction: Bool) -> Future<Void>{
        flatMap { $0.replace(with: models, on: conn, transaction: transaction) }
	}
}


//extension Future where Value: Collection, Value.Element: Model{
//
//	public func updateIfExists(on conn: Database, transaction: Bool) -> Future<Value>{
//		return flatMap { elements in
//			return elements.updateIfExists(on: conn, transaction: transaction)
//		}
//	}
//
//	public func upsert(on conn: Database, transaction: Bool) -> Future<Value>{
//		return flatMap { elements in
//			return elements.upsert(on: conn, transaction: transaction)
//		}
//	}
//}
