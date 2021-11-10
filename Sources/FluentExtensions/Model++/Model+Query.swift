//
//  Model+Query.swift
//  
//
//  Created by Brian Strobach on 10/26/21.
//

import Fluent

public extension Model {
    static func query(on request: Request) -> QueryBuilder<Self> {
        return query(on: request.db)
    }
}
