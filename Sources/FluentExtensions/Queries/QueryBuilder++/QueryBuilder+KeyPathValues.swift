//
//  QueryBuilder+KeyPathValues.swift
//  
//
//  Created by Brian Strobach on 10/25/21.
//

import Fluent

public extension QueryBuilder {
    func values<T>(of field: KeyPath<Model, T>, limit: Int?) async throws -> [T] {
        let models = try await at(most: limit)
        return models.map { $0[keyPath: field] }
    }
    
    func allValues<V>(at keyPath: KeyPath<Model, V>) async throws -> [V] {
        let allModels = try await all()
        return allModels.map { $0[keyPath: keyPath] }
    }

    func allValues<V>(at keyPath: KeyPath<Model, V?>) async throws -> [V] {
        let allModels = try await all()
        return allModels.compactMap { $0[keyPath: keyPath] }
    }

    func allIDs() async throws -> [Model.IDValue] {
        try await allValues(at: \.id)
    }
}
