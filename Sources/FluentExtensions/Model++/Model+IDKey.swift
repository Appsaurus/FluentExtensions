//
//  Model+IDKey.swift
//  
//
//  Created by Brian Strobach on 9/2/21.
//

import Fluent

extension Model{
    
    public static var idPropertyKeyPath: KeyPath<Self, IDProperty<Self, Self.IDValue>> {
        return \._$id
    }

    public static var idProperty: IDProperty<Self, Self.IDValue> {
        return Self()._$id
    }

    public static var idFieldKey: FieldKey{
        return idProperty.key
    }

    public static var idKeyStringPath: String{
        return idFieldKey.description
    }
}
