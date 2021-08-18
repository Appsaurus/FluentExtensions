//
//  QueryBuilderExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/28/18.
//

import Foundation
import FluentKit

public extension Model{
    static func random(on database: Database) -> Future<Self?>{
        return query(on: database).random()
    }
    
    static func random(on database: Database, count: Int) -> Future<[Self]>{
        return query(on: database).randomSlice(count: count)
    }
}

public extension QueryBuilder {

    func random() -> Future<Model?>{
        return self.randomSlice(count: 1).map({ model in
            return model.first
        })
    }

    func randomSlice(count: Int) -> Future<[Model]>{
        self.count().flatMap { total in
            guard total > 0 else { return self.emptyResults()}
            let queryRange = (0..<total).randomSubrange(count)
            return self.range(queryRange).all()
        }
    }
}

public extension QueryBuilder{
	func emptyResults() -> Future<[Model]> {
        return self.database.eventLoop.future([Model]())
	}
	func emptyResult() -> Future<Model?> {
		return self.database.eventLoop.future(nil)
	}
}

//public extension QueryBuilder {
//	func or(_ values: Database.QueryFilter...) -> Self {
//		return group(Database.queryFilterRelationOr) { (or) in
//			for value in values{
//				or.filter(custom: value)
//			}
//		}
//	}
//
//	func and(_ values: Database.QueryFilter...) -> Self {
//		return group(Database.queryFilterRelationAnd) { (and) in
//			for value in values{
//				and.filter(custom: value)
//			}
//		}
//	}
//}
