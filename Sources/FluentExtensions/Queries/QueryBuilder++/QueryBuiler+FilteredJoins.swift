//
//  QueryBuiler+FilteredJoins.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 3/10/25.
//



extension QueryBuilder {
    
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
