//
//  QueryBuiler+FilteredJoins.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 3/10/25.
//

extension QueryBuilder {
    /// Joins a parent model and applies filters to the joined model.
    /// - Parameters:
    ///   - parent: The key path to the parent property
    ///   - method: The join method to use (defaults to .inner)
    ///   - filters: The filters to apply to the joined model
    /// - Returns: The modified query builder
    @discardableResult
    public func join<To>(
        parent: KeyPath<Model, ParentProperty<Model, To>>,
        method: DatabaseQuery.Join.Method = .inner,
        where filters: ModelValueFilter<To>...
    ) -> Self {
        join(from: Model.self, parent: parent, method: method)
        for filterValue in filters {
            filter(To.self, filterValue)
        }
        return self
    }

    /// Joins a siblings relationship and applies filters to the pivot model.
    /// - Parameters:
    ///   - siblings: The key path to the siblings property
    ///   - filters: The filters to apply to the pivot model
    /// - Returns: The modified query builder
    @discardableResult
    public func join<To, Through>(
        siblings: KeyPath<Model, SiblingsProperty<Model, To, Through>>,
        where filters: ModelValueFilter<Through>...
    ) -> Self
        where To: FluentKit.Model, Through: FluentKit.Model
    {
        join(from: Model.self, siblings: siblings)
        for filterValue in filters {
            filter(Through.self, filterValue)
        }
        return self
    }
    
    /// Joins a foreign model with custom join conditions and applies filters.
    /// - Parameters:
    ///   - foreign: The foreign model type to join
    ///   - filter: The join condition filter
    ///   - method: The join method to use (defaults to .inner)
    ///   - filters: The filters to apply to the joined model
    /// - Returns: The modified query builder
    @discardableResult
    public func join<Foreign, Local, Value>(
        _ foreign: Foreign.Type = Foreign.self,
        on filter: JoinFilter<Foreign, Local, Value>,
        method: DatabaseQuery.Join.Method = .inner,
        where filters: ModelValueFilter<Foreign>...
    ) -> Self
        where Foreign: Schema, Local: Schema
    {
        join(foreign, on: filter, method: method)
        for filterValue in filters {
            self.filter(Foreign.self, filterValue)
        }
        return self
    }
    
    /// Joins a foreign model with custom join conditions.
    /// - Parameters:
    ///   - filter: The join condition filter
    ///   - method: The join method to use (defaults to .inner)
    /// - Returns: The modified query builder
    @discardableResult
    public func join<Foreign, Local, Value>(
        on filter: JoinFilter<Foreign, Local, Value>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self
        where Foreign: Schema, Local: Schema
    {
        return join(Foreign.self, on: filter, method: method)
    }
}
