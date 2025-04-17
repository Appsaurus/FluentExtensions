//
//  QueryBuilder+Timestampable.swift
//
//
//  Created by Brian Strobach on 10/26/21.
//

import Fluent

/// Extension providing timestamp-based filtering capabilities to QueryBuilder
public extension QueryBuilder where Model: Timestampable {
    /// Filters results based on a creation date range
    /// - Parameter range: The date range to filter by
    /// - Returns: The query builder for chaining
    @discardableResult
    func filterCreated(to range: Range<Date>) -> Self {
        return filter(Model.createdAtKey, to: range)
    }

    /// Filters results based on a creation date closed range
    /// - Parameter range: The date range to filter by
    /// - Returns: The query builder for chaining
    @discardableResult
    func filterCreated(to range: ClosedRange<Date>) -> Self {
        return filter(Model.createdAtKey, to: range)
    }

    /// Filters results based on an update date range
    /// - Parameter range: The date range to filter by
    /// - Returns: The query builder for chaining
    @discardableResult
    func filterUpdated(to range: Range<Date>) -> Self {
        return filter(Model.updatedAtKey, to: range)
    }

    /// Filters results based on an update date closed range
    /// - Parameter range: The date range to filter by
    /// - Returns: The query builder for chaining
    @discardableResult
    func filterUpdated(to range: ClosedRange<Date>) -> Self {
        return filter(Model.updatedAtKey, to: range)
    }
}
