//
//  Collection+Flatten.swift
//  
//
//  Created by Brian Strobach on 8/9/21.
//

import Fluent

extension Collection {
    func flatten<Value>(on database: Database) -> EventLoopFuture<[Value]>
    where Element == EventLoopFuture<Value>
    {
        return flatten(on: database.eventLoop)
    }
}
