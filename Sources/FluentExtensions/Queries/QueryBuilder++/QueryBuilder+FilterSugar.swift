//
//  QueryBuilder+FilterSugar.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 3/10/25.
//

/// Provides syntactic sugar extensions for filtering ``QueryBuilder`` instances
public extension QueryBuilder {
    
    /// Applies multiple filters to the query builder using variadic parameter syntax
    /// 
    /// This method allows you to chain multiple filters in a more readable syntax using
    /// the spread operator.
    ///
    /// ```swift
    /// query.filter(
    ///     .field("name", .equal, "John"),
    ///     .field("age", .greaterThan, 18)
    /// )
    /// ```
    ///
    /// - Parameter filters: A variadic list of ``ModelValueFilter`` instances to apply
    /// - Returns: The modified query builder instance for method chaining
    @discardableResult
    func filter(_ filters: ModelValueFilter<Model>...) -> Self {
        filter(filters)
    }
    
    /// Applies an array of filters to the query builder
    /// 
    /// This method serves as the implementation for the variadic filter method and can also
    /// be used directly with an array of filters.
    ///
    /// - Parameter filters: An array of ``ModelValueFilter`` instances to apply
    /// - Returns: The modified query builder instance for method chaining
    @discardableResult
    func filter(_ filters: [ModelValueFilter<Model>]) -> Self {
        filters.reduce(self) { $0.filter($1) }
    }
    
    /// Conditionally applies a filter based on a predicate
    /// 
    /// This method allows for dynamic filtering based on runtime conditions without
    /// cluttering the code with if statements.
    ///
    /// ```swift
    /// query.optionallyFilter(.field("status", .equal, "active"), if: shouldFilterActive)
    /// ```
    ///
    /// - Parameters:
    ///   - filter: The ``ModelValueFilter`` to apply if the condition is true
    ///   - predicate: An autoclosure that returns a Bool determining if the filter should be applied
    /// - Returns: The modified query builder instance for method chaining
    @discardableResult
    func optionallyFilter(_ filter: ModelValueFilter<Model>, if predicate: @autoclosure () -> Bool) -> Self {
        if (predicate()) {
            self.filter(filter)
        }
        return self
    }
}
