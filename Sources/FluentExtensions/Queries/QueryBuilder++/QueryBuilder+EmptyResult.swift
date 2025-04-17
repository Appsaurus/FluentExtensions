//
//  QueryBuilder+EmptyResult.swift
//  
//
//  Created by Brian Strobach on 9/1/21.
//

import FluentKit

/// Extension providing empty result utilities for QueryBuilder
public extension QueryBuilder {
    /// Returns an empty array of models
    /// - Returns: An empty array of the model type
    func emptyResults() -> [Model] {
        return [Model]()
    }

    /// Returns nil as an empty result
    /// - Returns: nil
    func emptyResult() -> Model? {
        return nil
    }
}
