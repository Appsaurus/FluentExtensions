//
//  QueryBuilder+KeyPathUpdates.swift
//  
//
//  Created by Brian Strobach on 10/26/21.
//

import Fluent

/// Extension providing key path-based update capabilities to QueryBuilder
public extension QueryBuilder {
    /// Updates records matching specific values with a new value
    /// - Parameters:
    ///   - keyPath: The property to update
    ///   - value: The new value to set
    ///   - values: The values to match against
    /// - Returns: The query builder for chaining
    func update<P: QueryableProperty>(_ keyPath: KeyPath<Model, P>,
                                      to value: P.Value,
                                      whereEqualToAny values: [P.Value]) -> Self where P.Model == Model {
        return self.filter(keyPath ~~ values).set(keyPath, to: value)
    }

    /// Updates records matching a specific value with a new value
    /// - Parameters:
    ///   - keyPath: The property to update
    ///   - newValue: The new value to set
    ///   - value: The value to match against
    /// - Returns: The query builder for chaining
    func update<P: QueryableProperty>(_ keyPath: KeyPath<Model, P>,
                                      to newValue: P.Value,
                                      whereEqualTo value: P.Value) -> Self where P.Model == Model {
        self.filter(keyPath == value).set(keyPath, to: value)
    }
}
