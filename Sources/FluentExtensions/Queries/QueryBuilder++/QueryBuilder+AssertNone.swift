//
//  QueryBuilder+AssertNone.swift
//  
//
//  Created by Brian Strobach on 10/14/21.
//

import Fluent
import VaporExtensions

public extension QueryBuilder {
    func assertNone(or error: Error = Abort(.badRequest)) throws -> Future<Void> {
        return count().is(==, 0, or: error).flattenVoid()
    }
}
