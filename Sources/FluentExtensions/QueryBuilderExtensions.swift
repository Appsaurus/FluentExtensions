//
//  QueryBuilderExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/28/18.
//

import Foundation
import Fluent

public extension Model{
    static func random(on conn: DatabaseConnectable) -> Future<Self?>{
        return query(on: conn).random()
    }
    
    static func random(on conn: DatabaseConnectable, count: Int) -> Future<[Self]>{
        return query(on: conn).randomSlice(count: count)
    }
}

public extension QueryBuilder {

    func random() -> Future<Result?>{
        return self.randomSlice(count: 1).map({ (model) -> (Result?) in
            return model.first
        })
    }

    func randomSlice(count: Int) -> Future<[Result]>{
        return self.count().flatMap(to: [Result].self) { total in
            guard total > 0 else { return self.emptyResults()}
            let queryRange = (0..<total).randomSubrange(count)
            return self.range(queryRange).all()
        }
    }
}

public extension QueryBuilder{
	func emptyResults() -> Future<[Result]> {
		return self.connection.eventLoop.newSucceededFuture(result: [Result]())
	}
	func emptyResult() -> Future<Result?> {
		return self.connection.eventLoop.newSucceededFuture(result: nil)
	}
}

public extension QueryBuilder {
	func or(_ values: Database.QueryFilter...) -> Self {
		return group(Database.queryFilterRelationOr) { (or) in
			for value in values{
				or.filter(custom: value)
			}
		}
	}

	func and(_ values: Database.QueryFilter...) -> Self {
		return group(Database.queryFilterRelationAnd) { (and) in
			for value in values{
				and.filter(custom: value)
			}
		}
	}
}
