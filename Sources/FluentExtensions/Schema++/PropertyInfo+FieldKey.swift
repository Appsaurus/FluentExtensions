//
//  PropertyInfo+FieldKey.swift
//  
//
//  Created by Brian Strobach on 8/30/21.
//

import Fluent
import Runtime

public extension PropertyInfo {
    var fieldName: String {
        var propertyName = name
        if propertyName.starts(with: "_") {
            propertyName = String(propertyName.dropFirst())
        }
        return propertyName
    }


    var fieldKey: FieldKey {
        return FieldKey(fieldName)
    }
}
