//
//  QueryBuilder+AssertNone.swift
//  
//
//  Created by Brian Strobach on 10/14/21.
//

import Fluent
import VaporExtensions

/// Extension providing assertion capabilities for ``QueryBuilder``
public extension QueryBuilder {
    /// Asserts that no records exist matching the current query, throwing an error if any are found.
    ///
    /// Use this method when you need to verify the absence of specific records in your database.
    /// For example, when ensuring uniqueness constraints or validating business rules.
    ///
    /// ```swift
    /// // Example: Ensure no users exist with the same email
    /// try await User.query()
    ///     .filter(\.$email == newEmail)
    ///     .assertNone(or: UserError.emailTaken)
    /// ```
    ///
    /// - Parameter error: The error to throw if any matching records exist. Defaults to `Abort(.badRequest)`.
    /// - Throws: The specified error if any matching records exist.
    func assertNone(or error: Error = Abort(.badRequest)) async throws {
        try await count().is(==, 0, or: error)
    }
}
