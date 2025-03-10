//
//  QueryBuilder+GroupBuilder.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 3/9/25.
//


extension QueryBuilder {
    @discardableResult
    public func and(
        _ closure: (QueryBuilder<Model>) throws -> ()
    ) rethrows -> Self {
        return try self.group(.and, closure)
    }
}

extension QueryBuilder {
    @discardableResult
    public func or(
        _ closure: (QueryBuilder<Model>) throws -> ()
    ) rethrows -> Self {
        return try self.group(.or, closure)
    }
}
