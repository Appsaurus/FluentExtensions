//
//  SchemaBuilder+Reflection.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/18/24.
//

/// Extension providing schema reflection capabilities to SchemaBuilder
public extension SchemaBuilder {
    /// Reflects and adds schema information for a single property to the schema builder.
    ///
    /// This method examines the provided property and determines the appropriate schema definition based on its type.
    /// It handles enum types, enum collections, and other schema reflectable types.
    ///
    /// - Parameters:
    ///   - property: The property to reflect into the schema
    ///   - fieldKeyBuilder: A closure that generates the FieldKey for the property. Defaults to FieldKey.reflectionBuilder
    /// - Returns: The SchemaBuilder instance for method chaining
    @discardableResult
    func reflectSchema(for property: ReflectedSchemaProperty,
                       fieldKeyBuilder: (ReflectedSchemaProperty) -> FieldKey = FieldKey.reflectionBuilder) -> SchemaBuilder {
        let propertyType = property.type
        let fieldKey = fieldKeyBuilder(property)
        if let enumSchemaReflectable = propertyType as? EnumSchemaReflectable.Type {
            return enumSchemaReflectable.reflectEnumSchema(with: fieldKey, to: self)
        }
        else if let enumCollectionSchemaReflectable = propertyType as? EnumCollectionSchemaReflectable.Type {
            return enumCollectionSchemaReflectable.reflectEnumCollectionSchema(with: fieldKey, to: self)
        }
        else if let schemaReflectable = property.type as? SchemaReflectable.Type {
            return schemaReflectable.reflectSchema(with: fieldKey, to: self)
        }
        return self
    }
    
    /// Reflects and adds schema information for all properties of a given type to the schema builder.
    ///
    /// This method iterates through all reflected properties of the provided type and adds them to the schema.
    ///
    /// - Parameters:
    ///   - type: The type whose properties should be reflected into the schema
    ///   - fieldKeyBuilder: A closure that generates the FieldKey for each property. Defaults to FieldKey.reflectionBuilder
    /// - Returns: The SchemaBuilder instance for method chaining
    @discardableResult
    func reflectSchema<M: Fields>(of type: M.Type,
                                  fieldKeyBuilder: (ReflectedSchemaProperty) -> FieldKey = FieldKey.reflectionBuilder) -> Self {
        try? type.reflectedSchemaProperties().forEach { property in
            reflectSchema(for: property, fieldKeyBuilder: fieldKeyBuilder)
        }
        return self
    }
    
    /// Adds a field to the schema with the specified key, type, and constraints.
    ///
    /// - Parameters:
    ///   - key: The key identifying the field in the schema
    ///   - swiftType: The Swift type of the field
    ///   - isEnum: Whether the field represents an enum type. Defaults to false
    ///   - constraints: Variadic list of constraints to apply to the field
    /// - Returns: The SchemaBuilder instance for method chaining
    func field(
        _ key: FieldKey,
        _ swiftType: Any.Type,
        isEnum: Bool = false,
        _ constraints: DatabaseSchema.FieldConstraint...
    ) -> Self {
        self.field(.definition(
            name: .key(key),
            dataType: .init(swiftType, defineAsEnum: isEnum),
            constraints: constraints
        ))
    }
}

/// Extension providing reflection building capabilities for FieldKey
public extension FieldKey {
    /// Default reflection builder that converts ReflectedSchemaProperty instances to FieldKeys.
    /// This is used as the default field key builder in schema reflection methods.
    static var reflectionBuilder: (ReflectedSchemaProperty) -> FieldKey = { property in
        return property.fieldKey
    }
}
