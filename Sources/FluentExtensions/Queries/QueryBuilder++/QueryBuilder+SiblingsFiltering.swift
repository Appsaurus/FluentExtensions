//
//  QueryBuilder+SiblingsFiltering.swift
//
//
//  Created by Brian Strobach on 1/15/25.
//

import Fluent
import Vapor

/// Extension providing siblings-based filtering capabilities to QueryBuilder
public extension QueryBuilder {
    /// Filters results based on a condition applied to a siblings relationship
    /// - Parameters:
    ///   - siblingsProperty: The siblings relationship property to filter on
    ///   - filter: The filter to apply to the related model
    /// - Returns: The query builder for chaining
    @discardableResult
    func filter<Through, To>(
        _ siblingsProperty: KeyPath<Model, SiblingsProperty<Model, To, Through>>,
        _ filter: ModelValueFilter<To>
    ) -> Self where Through: FluentKit.Model, To: FluentKit.Model {
        self.join(siblings: siblingsProperty)
            .filter(To.self, filter)
        return self
    }

    /// Filters results based on multiple values for a field in the related model
    /// - Parameters:
    ///   - siblingsProperty: The siblings relationship property to filter on
    ///   - field: The field in the related model to filter on
    ///   - values: The values to filter by
    /// - Returns: The query builder for chaining
    @discardableResult
    func filter<Through, To, V>(
        _ siblingsProperty: KeyPath<Model, SiblingsProperty<Model, To, Through>>,
        _ field: KeyPath<To, FieldProperty<To, V>>,
        values: [V]
    ) -> Self where Through: FluentKit.Model, To: FluentKit.Model, V: Codable {
        filter(siblingsProperty, field ~~ values)
    }
    
    /// Filters results based on a single value for a field in the related model
    /// - Parameters:
    ///   - siblingsProperty: The siblings relationship property to filter on
    ///   - field: The field in the related model to filter on
    ///   - value: The value to filter by
    /// - Returns: The query builder for chaining
    @discardableResult
    func filter<Through, To, V>(
        _ siblingsProperty: KeyPath<Model, SiblingsProperty<Model, To, Through>>,
        _ field: KeyPath<To, FieldProperty<To, V>>,
        _ value: V
    ) -> Self where Through: FluentKit.Model, To: FluentKit.Model, V: Codable {
        filter(siblingsProperty, field ~~ [value])
    }
}
