//
//  QueryBuilder+EmptyResult.swift
//  
//
//  Created by Brian Strobach on 9/1/21.
//

import FluentKit

public extension QueryBuilder{
    func emptyResults() -> Future<[Model]> {
        return self.database.eventLoop.future([Model]())
    }
    func emptyResult() -> Future<Model?> {
        return self.database.eventLoop.future(nil)
    }
}

