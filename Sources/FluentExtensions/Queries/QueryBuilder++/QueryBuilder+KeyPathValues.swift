//
//  QueryBuilder+KeyPathValues.swift
//  
//
//  Created by Brian Strobach on 10/25/21.
//

import Fluent

public extension QueryBuilder {

    func allValues<V>(at keyPath: KeyPath<Model, V>) -> Future<[V]> {
        return all().map({$0.map({$0[keyPath: keyPath]})})
    }

    func allValues<V>(at keyPath: KeyPath<Model, V?>) -> Future<[V]> {
        return all().map { values in
            return values.map({$0[keyPath: keyPath]})
        }.map { $0.compactMap { $0 }}        
    }

    func allIDs() -> Future<[Model.IDValue]> {
        return allValues(at: \.id)
    }
}
