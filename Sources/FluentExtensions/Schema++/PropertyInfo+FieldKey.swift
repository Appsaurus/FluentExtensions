//
//  PropertyInfo+FieldKey.swift
//  
//
//  Created by Brian Strobach on 8/30/21.
//

import Fluent
import Runtime


public extension MirroredProperty {
    var fieldName: String {
        name.droppingUnderscorePrefix
    }

    var fieldKey: FieldKey {
        return FieldKey(fieldName)
    }
}

public extension PropertyInfo {
    var fieldName: String {
        name.droppingUnderscorePrefix
    }


    var fieldKey: FieldKey {
        return FieldKey(fieldName)
    }
}


extension TypeInfo {
    var fieldName: String {
        name.droppingUnderscorePrefix
    }

    var fieldKey: FieldKey {
        return FieldKey(fieldName)
    }
}

//Converts underscore-prefixed wrapped property names
internal extension String {
    var droppingUnderscorePrefix: String {
        if self.starts(with: "_") {
            return String(self.dropFirst())
        }
        return self
    }
}
