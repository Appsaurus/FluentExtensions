//
//  EnumCollectionSchemaReflectable.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/18/24.
//

/// A protocol that enables automatic schema reflection for collections of enumeration types.
///
/// This protocol is designed to work with Fluent's schema builder to automatically configure
/// database fields for properties that contain collections of enum values.
///
/// - Note: The protocol is primarily used internally by the schema reflection system and shouldn't
///         need to be implemented directly by most users.
protocol EnumCollectionSchemaReflectable {
    /// Reflects the schema for a collection of enum values.
    ///
    /// - Parameters:
    ///   - key: The field key under which to store the enum collection in the database
    ///   - builder: The schema builder to configure
    /// - Returns: The configured schema builder
    static func reflectEnumCollectionSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder
}

/// Provides default implementation for stored properties containing collections of enum values.
extension FieldProperty: EnumCollectionSchemaReflectable where Value: Collection, Value.Element: CaseIterable & RawRepresentable {
    @discardableResult
    public static func reflectEnumCollectionSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, [Value.Element.RawValue].self, .required)
    }
}

/// Provides default implementation for optional stored properties containing collections of enum values.
extension OptionalFieldProperty: EnumCollectionSchemaReflectable where Value.WrappedType: Collection, Value.WrappedType.Element: CaseIterable & RawRepresentable {
    @discardableResult
    public static func reflectEnumCollectionSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, [Value.WrappedType.Element.RawValue].self, .required)
    }
}
