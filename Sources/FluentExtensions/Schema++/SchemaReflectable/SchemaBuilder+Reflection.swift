//
//  SchemaBuilder+Reflection.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/18/24.
//


public extension SchemaBuilder {
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
    
    @discardableResult
    func reflectSchema<M: Fields>(of type: M.Type,
                                  fieldKeyBuilder: (ReflectedSchemaProperty) -> FieldKey = FieldKey.reflectionBuilder) -> Self {
        try? type.reflectedSchemaProperties().forEach { property in
            reflectSchema(for: property, fieldKeyBuilder: fieldKeyBuilder)
        }
        return self
    }
    
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

public extension FieldKey {
    static var reflectionBuilder: (ReflectedSchemaProperty) -> FieldKey = { property in
        return property.fieldKey
    }
}
