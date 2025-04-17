//
//  Fields+ReflectedProperties.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/18/24.
//

import Fluent
import RuntimeExtensions

/// Extension providing reflection capabilities for Fluent's `Fields` protocol.
///
/// This extension enables automatic property reflection and schema generation for Fluent models,
/// which is particularly useful for database migrations and model introspection.
extension Fields {
    /// Returns an array of mirrored properties for the current type.
    ///
    /// Uses Swift's Mirror API to reflect and return all properties defined in the type.
    ///
    /// - Returns: An array of `MirroredProperty` instances representing each property in the type.
    static var mirroredProperties: [MirroredProperty] {
        return Mirror.properties(of: self)
    }
    
    /// Retrieves detailed property information for all properties in the type.
    ///
    /// Creates an instance of the type and uses runtime reflection to gather detailed
    /// property information.
    ///
    /// - Returns: An array of `PropertyInfo` instances containing metadata about each property.
    /// - Throws: An error if property reflection fails.
    static func propertiesInfo() throws -> [PropertyInfo] {
        return try RuntimeExtensions.properties(Self.init())
    }
    
    /// Returns an array of reflected schema properties for database schema generation.
    ///
    /// This method combines runtime property information with Fluent's schema system to enable
    /// automatic database schema generation.
    ///
    /// - Returns: An array of `ReflectedSchemaProperty` instances that can be used for schema creation.
    /// - Throws: An error if property reflection or schema generation fails.
    static func reflectedSchemaProperties() throws -> [ReflectedSchemaProperty] {
        try propertiesInfo()
    }
}
