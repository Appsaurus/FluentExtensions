//
//  QueryBuilder+SiblingsFiltering.swift
//
//
//  Created by Brian Strobach on 1/15/25.
//

import Fluent
import Vapor

public extension QueryBuilder {
    @discardableResult
    func filter<Through, To>(
        _ siblingsProperty: KeyPath<Model, SiblingsProperty<Model, To, Through>>,
        _ filter: ModelValueFilter<To>
    ) -> Self where Through: FluentKit.Model, To: FluentKit.Model {

        self.join(siblings: siblingsProperty)
            .filter(To.self, filter)
            
        return self
    }


    @discardableResult
    func filter<Through, To, V>(
        _ siblingsProperty: KeyPath<Model, SiblingsProperty<Model, To, Through>>,
        _ field: KeyPath<To, FieldProperty<To, V>>,
        values: [V]
    ) -> Self where Through: FluentKit.Model, To: FluentKit.Model, V: Codable {
        filter(siblingsProperty, field ~~ values)
    }
    
    @discardableResult
    func filter<Through, To, V>(
        _ siblingsProperty: KeyPath<Model, SiblingsProperty<Model, To, Through>>,
        _ field: KeyPath<To, FieldProperty<To, V>>,
        _ value: V
    ) -> Self where Through: FluentKit.Model, To: FluentKit.Model, V: Codable {
        filter(siblingsProperty, field ~~ [value])
    }
}
