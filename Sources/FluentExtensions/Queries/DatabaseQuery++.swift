//
//  DatabaseQuery++.swift
//  
//
//  Created by Brian Strobach on 9/7/21.
//

import Fluent

public extension DatabaseQuery.Filter.Method {
    static var inSubSet: Self {
        .subset(inverse: false)
    }

    static var notInSubSet: Self {
        .subset(inverse: true)
    }
}


public extension DatabaseQuery.Sort {
    static func sort<M: Model, V: QueryableProperty>(_ keyPath: KeyPath<M, V>, _ direction: DatabaseQuery.Sort.Direction) -> DatabaseQuery.Sort {
        DatabaseQuery.Sort.sort(keyPath.databaseQueryField, direction)
    }
    
    static func descending<M: Model, V: QueryableProperty>(_ keyPath: KeyPath<M, V>) -> DatabaseQuery.Sort {
        sort(keyPath, .descending)
    }
    
    static func ascending<M: Model, V: QueryableProperty>(_ keyPath: KeyPath<M, V>) -> DatabaseQuery.Sort {
        sort(keyPath, .ascending)
    }
}
