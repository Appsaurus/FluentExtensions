//
//  Model+Existence.swift
//  
//
//  Created by Brian Strobach on 9/2/21.
//

import VaporExtensions
import Fluent

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
