//
//  PropertyInfo+FieldKey.swift
//
//
//  Created by Brian Strobach on 8/30/21.
//

import Fluent
import Runtime

/// Extends `MirroredProperty` to provide Fluent field key generation functionality.
public extension MirroredProperty {
    /// The field name derived from the property name with any underscore prefix removed.
    var fieldName: String {
        name.droppingUnderscorePrefix
    }

    /// Creates a Fluent `FieldKey` from the property's field name.
    var fieldKey: FieldKey {
        return FieldKey(fieldName)
    }
}

/// Extends `PropertyInfo` to provide Fluent field key generation functionality.
public extension PropertyInfo {
    /// The field name derived from the property name with any underscore prefix removed.
    var fieldName: String {
        name.droppingUnderscorePrefix
    }

    /// Creates a Fluent `FieldKey` from the property's field name.
    var fieldKey: FieldKey {
        return FieldKey(fieldName)
    }
}

/// Extends `TypeInfo` to provide Fluent field key generation functionality.
extension TypeInfo {
    /// The field name derived from the type name with any underscore prefix removed.
    var fieldName: String {
        name.droppingUnderscorePrefix
    }

    /// Creates a Fluent `FieldKey` from the type's field name.
    var fieldKey: FieldKey {
        return FieldKey(fieldName)
    }
}

/// Internal utility for string manipulation.
internal extension String {
    /// Removes the underscore prefix from a string if present.
    ///
    /// This is particularly useful for handling property wrappers in Swift where the
    /// actual storage property is prefixed with an underscore.
    ///
    /// - Returns: The string with any leading underscore removed.
    var droppingUnderscorePrefix: String {
        if self.starts(with: "_") {
            return String(self.dropFirst())
        }
        return self
    }
}
