//
//  Model+Future.swift
//  
//
//  Created by Brian Strobach on 10/26/21.
//

import Fluent

public extension Model {
    func toFuture(on database: Database) -> Future<Self> {
        return database.eventLoop.future(self)
    }

    func toFuture(on eventLoopReferencing: EventLoopReferencing) -> Future<Self> {
        return eventLoopReferencing.eventLoop.future(self)
    }
}
