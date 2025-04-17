//
//  FieldKey+StringInit.swift
//
//
//  Created by Brian Strobach on 8/30/21.
//

import Fluent

/// Provides convenient string-based initialization for `FieldKey`.
///
/// This extension simplifies the creation of database field keys by allowing direct initialization
/// from string literals, making database schema definitions more concise and readable.
///
/// ## Example Usage:
/// ```swift
/// let nameField = FieldKey("name")
/// let emailField = FieldKey("email")
/// ```
///
/// - Note: This is particularly useful when defining database schemas or performing queries
///         where field keys need to be created from dynamic string values.
public extension FieldKey {
    /// Initializes a new `FieldKey` instance from a string value.
    ///
    /// - Parameter string: The string value to use as the field key.
    init(_ string: String) {
        self.init(stringLiteral: string)
    }
}
