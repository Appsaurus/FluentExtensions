//
//  QueryBuilderExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/28/18.
//

import FluentKit

public extension Model {
    static func random(on database: Database) async throws -> Self? {
        try await query(on: database).random()
    }
    
    static func random(on database: Database, count: Int) async throws -> [Self] {
        try await query(on: database).randomSlice(count: count)
    }
}

public extension QueryBuilder {
    func sort(_ field: String, _ direction: DatabaseQuery.Sort.Direction = .ascending) -> Self {
        return self.sort(FieldKey(extendedGraphemeClusterLiteral: field), direction)
    }

    func random() async throws -> Model? {
        let randomModels = try await randomSlice(count: 1)
        return randomModels.first
    }

    func randomSlice(count: Int) async throws -> [Model] {
        let total = try await self.count()
        guard total > 0 else { return [] }
        let queryRange = (0..<total).randomSubrange(count)
        return try await self.range(queryRange).all()
    }
}
