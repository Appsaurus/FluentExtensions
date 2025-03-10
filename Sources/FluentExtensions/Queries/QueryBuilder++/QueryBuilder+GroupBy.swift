//
//  QueryBuilder+GroupBy.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 3/10/25.
//

public extension QueryBuilder {
    
    @discardableResult
    func groupBy<T>(_ field: KeyPath<Model, T>?) -> Self {
        guard let field = field else { return self }
        return groupBy(field)
    }

    func groupedValues<T>(of field: KeyPath<Model, T>, limit: Int?) async throws -> [T] {
        try await groupBy(field).values(of: field, limit: limit)
    }

}
