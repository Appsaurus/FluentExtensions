//
//  QueryBuilderExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/28/18.
//

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

    func sort(_ field: String, _ direction: DatabaseQuery.Sort.Direction = .ascending) -> Self {
        
        return self.sort(FieldKey(extendedGraphemeClusterLiteral: field), direction)
    }

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
