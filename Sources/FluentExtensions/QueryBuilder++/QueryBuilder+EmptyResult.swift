//
//  File.swift
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

//public extension QueryBuilder {
//    func or(_ values: Database.QueryFilter...) -> Self {
//        return group(Database.queryFilterRelationOr) { (or) in
//            for value in values{
//                or.filter(custom: value)
//            }
//        }
//    }
//
//    func and(_ values: Database.QueryFilter...) -> Self {
//        return group(Database.queryFilterRelationAnd) { (and) in
//            for value in values{
//                and.filter(custom: value)
//            }
//        }
//    }
//}
