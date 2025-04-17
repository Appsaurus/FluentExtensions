//
//  QueryBuilder+GroupBuilder.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 3/9/25.
//

extension QueryBuilder {
    /// Creates a grouped AND condition in the query
    ///
    /// This method allows for complex logical grouping of conditions using AND operators.
    /// The conditions are defined in the closure parameter.
    ///
    /// ```swift
    /// query.and { builder in
    ///     builder.filter(\.$status, .equal, "active")
    ///     builder.filter(\.$age, .greaterThan, 18)
    /// }
    /// ```
    ///
    /// - Parameter closure: A closure that takes a ``QueryBuilder`` and defines the conditions to group
    /// - Returns: The modified query builder instance for method chaining
    /// - Throws: Any error that might occur during the query building process
    @discardableResult
    public func and(
        _ closure: (QueryBuilder<Model>) throws -> ()
    ) rethrows -> Self {
        return try self.group(.and, closure)
    }
}

extension QueryBuilder {
    /// Creates a grouped OR condition in the query
    ///
    /// This method allows for complex logical grouping of conditions using OR operators.
    /// The conditions are defined in the closure parameter.
    ///
    /// ```swift
    /// query.or { builder in
    ///     builder.filter(\.$status, .equal, "pending")
    ///     builder.filter(\.$status, .equal, "processing")
    /// }
    /// ```
    ///
    /// - Parameter closure: A closure that takes a ``QueryBuilder`` and defines the conditions to group
    /// - Returns: The modified query builder instance for method chaining
    /// - Throws: Any error that might occur during the query building process
    @discardableResult
    public func or(
        _ closure: (QueryBuilder<Model>) throws -> ()
    ) rethrows -> Self {
        return try self.group(.or, closure)
    }
}
