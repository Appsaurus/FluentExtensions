//
//  Database+EventLoopReferencing.swift
//  
//
//  Created by Brian Strobach on 9/8/21.
//

import VaporExtensions

public extension Database {
    func fail<V>(with error: Error) -> EventLoopFuture<V> {
        eventLoop.fail(with: error)
    }

    func toFuture<V>(_ value: V) -> EventLoopFuture<V> {
        eventLoop.future(value)
    }

    func future<V>(_ value: V) -> Future<V> {
        toFuture(value)
    }
}
