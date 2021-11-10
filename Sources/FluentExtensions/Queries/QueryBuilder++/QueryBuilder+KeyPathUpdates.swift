//
//  QueryBuilder+KeyPathUpdates.swift
//  
//
//  Created by Brian Strobach on 10/26/21.
//

import Fluent

public extension QueryBuilder {

    func update<P: QueryableProperty>(_ keyPath: KeyPath<Model, P>,
                                      to value: P.Value,
                                      whereEqualToAny values: [P.Value]) -> Self where P.Model == Model {
        return self.filter(keyPath ~~ values).set(keyPath, to: value)
    }

    func update<P: QueryableProperty>(_ keyPath: KeyPath<Model, P>,
                                      to newValue: P.Value,
                                      whereEqualTo value: P.Value) -> Self where P.Model == Model {
        self.filter(keyPath == value).set(keyPath, to: value)
    }
}
