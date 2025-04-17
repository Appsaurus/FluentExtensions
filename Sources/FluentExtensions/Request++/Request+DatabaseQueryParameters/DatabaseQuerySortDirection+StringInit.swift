//
//  DatabaseQuerySortDirection+StringInit.swift
//  
//
//  Created by Brian Strobach on 9/29/21.
//

import Fluent

/// A convenient extension to create sort directions from string inputs.
///
/// This extension provides string-based initialization for database query sort directions,
/// making it easier to parse and handle sort parameters from user input or API requests.
public extension DatabaseQuery.Sort.Direction {
    /// Creates a sort direction from a string value.
    ///
    /// The initializer is case-insensitive and supports common sort direction terminology.
    ///
    /// - Parameter string: A string representing the desired sort direction.
    ///   Supported values include:
    ///   - "asc" or "ascending" for ascending order
    ///   - "desc" or "descending" for descending order
    ///   - Any other string value will be treated as a custom sort direction
    init(_ string: String) {
        switch string.lowercased() {
        case "asc", "ascending":
            self = .ascending
        case "desc", "descending":
            self = .descending
        default: self = .custom(string)
        }
    }
}
