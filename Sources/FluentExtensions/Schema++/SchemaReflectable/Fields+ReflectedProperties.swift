//
//  Fields+ReflectedProperties.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/18/24.
//

import Fluent
import RuntimeExtensions

extension Fields {
    static var mirroredProperties: [MirroredProperty]{
        return Mirror.properties(of: self)
    }
    
    static func propertiesInfo() throws -> [PropertyInfo]{
        return try RuntimeExtensions.properties(Self.init())
    }
    
    static func reflectedSchemaProperties() throws -> [ReflectedSchemaProperty] {
        try propertiesInfo()
        //        return mirroredProperties
        
    }
}
