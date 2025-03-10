//
//  QueryBuilder+FilterSugar.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 3/10/25.
//

public extension QueryBuilder {
    
    @discardableResult
    func filter(_ filters: ModelValueFilter<Model>...) -> Self {
        filter(filters)
    }
    
    @discardableResult
    func filter(_ filters: [ModelValueFilter<Model>]) -> Self {
        filters.reduce(self) { $0.filter($1) }
    }
    
    @discardableResult
    func optionallyFilter(_ filter: ModelValueFilter<Model>, if predicate: @autoclosure () -> Bool) -> Self {
        if (predicate()) {
            self.filter(filter)
        }
        return self
    }
}
