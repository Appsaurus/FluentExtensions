//
//  FieldKey+StringInit.swift
//  
//
//  Created by Brian Strobach on 8/30/21.
//

import Fluent

public extension FieldKey {
    init(_ string: String) {
        self.init(stringLiteral: string)
    }
}
