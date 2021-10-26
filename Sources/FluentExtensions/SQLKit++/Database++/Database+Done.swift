//
//  Database+Done.swift
//  
//
//  Created by Brian Strobach on 9/27/21.
//

public extension Future where Value == Void {
    static func done(on database: Database) -> Future<Void> {
        database.eventLoop.makeSucceededFuture({}())
    }
}
