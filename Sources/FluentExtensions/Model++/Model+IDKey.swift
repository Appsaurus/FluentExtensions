//
//  Model+IDKey.swift
//  
//
//  Created by Brian Strobach on 9/2/21.
//

import Fluent

public extension Model{
    
    static var idPropertyKeyPath: KeyPath<Self, IDProperty<Self, Self.IDValue>> {
        return \._$id
    }

    static var idProperty: IDProperty<Self, Self.IDValue> {
        return Self()._$id
    }

    static var idFieldKey: FieldKey{
        return idProperty.key
    }

    static var idKeyStringPath: String{
        return idFieldKey.description
    }
}
