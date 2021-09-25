//
//  DatabaseQuery++.swift
//  
//
//  Created by Brian Strobach on 9/7/21.
//

import Fluent

extension DatabaseQuery.Filter.Method {
    static var inSubSet: Self {
        .subset(inverse: false)
    }

    static var notInSubSet: Self {
        .subset(inverse: true)
    }
}


extension DatabaseQuery.Sort {
    static func sort<M: Model, V: QueryableProperty>(_ keyPath: KeyPath<M, V>, _
                                                        direction: DatabaseQuery.Sort.Direction = .descending) -> DatabaseQuery.Sort {
        DatabaseQuery.Sort.sort(keyPath.databaseQueryField, direction)
    }
}
