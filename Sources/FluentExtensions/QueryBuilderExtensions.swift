//
//  QueryBuilderExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/28/18.
//

import Foundation
import Fluent


extension Model where Database: QuerySupporting, ID == Int{
    public static func random(on conn: DatabaseConnectable) -> Future<Self?>{
        return query(on: conn).random()
    }

    public static func random(on conn: DatabaseConnectable, count: Int) -> Future<[Self]>{
        return query(on: conn).random(count: count)
    }
}

extension QueryBuilder where Result: Model, Result.ID == Int{
	public func random() -> Future<Result?>{
        return self.count().flatMap(to: Optional<Result>.self) { total in
            guard total > 0 else { return self.emptyResult() }
            return self.filter(Result.idKey == .random(in: 0..<total)).first()
        }
	}

	public func random(count: Int) -> Future<[Result]>{
		return self.count().flatMap(to: [Result].self) { total in
			guard total > 0 else { return self.emptyResults()}
			let queryRange = (0..<total).randomSubrange(count)
			return self.range(queryRange).all()
		}
	}
}

extension QueryBuilder{
	public func emptyResults() -> Future<[Result]> {
		return self.connection.eventLoop.newSucceededFuture(result: [Result]())
	}
	public func emptyResult() -> Future<Result?> {
		return self.connection.eventLoop.newSucceededFuture(result: nil)
	}
}

extension QueryBuilder {
	public func or(_ values: Database.QueryFilter...) -> Self {
		return group(Database.queryFilterRelationOr) { (or) in
			for value in values{
				or.filter(custom: value)
			}
		}
	}

	public func and(_ values: Database.QueryFilter...) -> Self {
		return group(Database.queryFilterRelationAnd) { (and) in
			for value in values{
				and.filter(custom: value)
			}
		}
	}
}
