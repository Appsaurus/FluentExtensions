//
//  SQLQueryFetcher++.swift
//
//
//  Created by Brian Strobach on 10/26/21.
//

import SQLKit

/// Extends `SQLQueryFetcher` to provide simplified value extraction from SQL query results
extension SQLQueryFetcher {
    /// Decodes and flattens SQL query results into an array of decoded values.
    ///
    /// This method streamlines the process of extracting values from SQL query results by automatically
    /// decoding and flattening the results into a single array. It's particularly useful when you're only
    /// interested in a single column's values from your query results.
    ///
    /// - Note: The method expects the SQL query to return results that can be decoded into a dictionary
    ///         with string keys and decodable values.
    ///
    /// - Parameter type: The type to decode the values into
    /// - Returns: An array of decoded values
    /// - Throws: A decoding error if the query results cannot be decoded into the specified type
    ///
    /// ## Example
    /// ```swift
    /// // Query to get all user names
    /// let names = try await db.raw("SELECT name FROM users")
    ///     .all(decodingValues: String.self)
    /// // Result: ["John", "Jane", "Bob"]
    ///
    /// // Query to get all user ages
    /// let ages = try await db.raw("SELECT age FROM users")
    ///     .all(decodingValues: Int.self)
    /// // Result: [25, 30, 35]
    /// ```
    public func all<A>(decodingValues type: A.Type) async throws -> [A]
        where A: Decodable
    {
        let keyedValues = try await all(decoding: [String: A].self)
        return keyedValues.flatMap { $0.values }
    }
}
