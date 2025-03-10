//
//  QueryBuilder+Limit.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 3/10/25.
//


public extension QueryBuilder {
    // MARK: Range
    func at(most max: Int) async throws -> [Model] {
        try await limit(max).all()
    }

    func at(most max: Int?) async throws -> [Model] {
        guard let max = max else { return try await all() }
        return try await at(most: max)
    }
}