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
        name.fieldName
    }


    var fieldKey: FieldKey {
        return FieldKey(fieldName)
    }
}


extension TypeInfo {
    var fieldName: String {
        name.fieldName
    }

    var fieldKey: FieldKey {
        return FieldKey(fieldName)
    }
}

//Converts underscore-prefixed wrapped property names
fileprivate extension String {
    var fieldName: String {
        if self.starts(with: "_") {
            return String(self.dropFirst())
        }
        return self
    }
}
