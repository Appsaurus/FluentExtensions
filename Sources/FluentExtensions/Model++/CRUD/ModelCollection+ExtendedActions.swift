//
//  Model+CollectionExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 7/2/18.
//

import Foundation
import Fluent
import Vapor


public extension Collection where Element: Model{
    func save(on database: Database) -> EventLoopFuture<Void> {
        guard self.count > 0 else {
            return database.eventLoop.makeSucceededFuture(())
        }

        return compactMap({$0.save(on: database)}).flatten(on: database.eventLoop)
    }

    func update(on database: Database) -> EventLoopFuture<Void> {
        guard self.count > 0 else {
            return database.eventLoop.makeSucceededFuture(())
        }

        return compactMap({$0.update(on: database, force: true)}).flatten(on: database.eventLoop)
    }

}


public extension Collection where Element: Model{
    func upsert(on database: Database) -> Future<Void>{
        compactMap { $0.upsert(on: database) }.flatten(on: database.eventLoop).flattenVoid()
    }

    func updateIfExists(on database: Database) -> Future<Void>{
        compactMap { $0.updateIfExists(on: database) }.flatten(on: database.eventLoop).flattenVoid()
    }

    func upsert(on database: Database, transaction: Bool = true) -> Future<Void>{
        return performBatch(action: upsert, on: database, transaction: transaction)
    }

    func replace(with models: Future<Self>, on database: Database, transaction: Bool) -> Future<Void>{
         map { return $0.delete(on: database) }
            .compactMap{ _ in
                models.save(on: database, transaction: transaction)
            }.flatten(on: database.eventLoop)
    }
}

public extension Future where Value: Collection, Value.Element: Model{
    func upsert(on database: Database, transaction: Bool) -> Future<Void>{
         flatMap { $0.upsert(on: database, transaction: transaction) }
    }


    func replace(with models: Future<Value>, on database: Database, transaction: Bool) -> Future<Void>{
        flatMap { $0.replace(with: models, on: database, transaction: transaction) }
	}
}


//public extension Future where Value: Collection, Value.Element: Model{
//
//	func updateIfExists(on database: Database, transaction: Bool) -> Future<Value>{
//		return flatMap { elements in
//			return elements.updateIfExists(on: database, transaction: transaction)
//		}
//	}
//
//	func upsert(on database: Database, transaction: Bool) -> Future<Value>{
//		return flatMap { elements in
//			return elements.upsert(on: database, transaction: transaction)
//		}
//	}
//}
