//
//  Model+Query.swift
//
//
//  Created by Brian Strobach on 10/26/21.
//

import Fluent

public extension Model {
    /// Creates a query builder for the model using the request's database
    /// - Parameter request: The request containing the database connection
    /// - Returns: A QueryBuilder instance for the model
    static func query(on request: Request) -> QueryBuilder<Self> {
        return query(on: request.db)
    }
}
