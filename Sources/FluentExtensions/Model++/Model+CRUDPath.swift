//
//  Model+CRUDPath.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 8/26/24.
//

import Swiftest

public extension Model {
    /// Generates a standardized path name for CRUD operations on the model
    ///
    /// The path name is created by:
    /// 1. Taking the schema or alias name
    /// 2. Removing any "Entity" suffix
    /// 3. Pluralizing the result
    /// 4. Formatting with hyphens
    ///
    /// For example: "UserEntity" becomes "users"
    static var crudPathName: String {
        return schemaOrAlias
            .removingSuffix("Entity")
            .pluralized
            .formatted(as: .hyphenated)
    }
}

extension String {
    /// Converts a string to its plural form using basic English pluralization rules
    /// 
    /// - Note: This is a simplified pluralization implementation that handles common cases:
    ///   - Words ending in "ings" remain unchanged
    ///   - Words ending in "y" change to "ies"
    ///   - Words ending in "s" add "es"
    ///   - All other words add "s"
    var pluralized: String {
        if ends(with: "ings") {
            return self
        }
        if ends(with: "y") {
            return "\(self.dropLast())ies"
        }
        if ends(with: "s") {
            return "\(self)es"
        }
        return "\(self)s"
    }
}
