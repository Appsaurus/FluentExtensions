//
//  Model+IDKey.swift
//
//
//  Created by Brian Strobach on 9/2/21.
//

import Fluent

public extension Model{
    
    /// Returns the key path to the model's ID property
    /// - Returns: KeyPath pointing to the model's ID property
    static var idPropertyKeyPath: KeyPath<Self, IDProperty<Self, Self.IDValue>> {
        return \._$id
    }

    /// Returns the model's ID property instance
    /// - Returns: The ID property of a new model instance
    static var idProperty: IDProperty<Self, Self.IDValue> {
        return Self()._$id
    }

    /// Returns the field key used for the model's ID in the database
    /// - Returns: The FieldKey representing the ID column
    static var idFieldKey: FieldKey {
        return idProperty.key
    }

    /// Returns the string representation of the model's ID field key
    /// - Returns: String representation of the ID field key
    static var idKeyStringPath: String {
        return idFieldKey.description
    }
}
