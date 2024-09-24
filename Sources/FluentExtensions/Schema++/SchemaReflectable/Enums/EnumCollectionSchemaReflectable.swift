//
//  EnumCollectionSchemaReflectable.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/18/24.
//

protocol EnumCollectionSchemaReflectable {
    static func reflectEnumCollectionSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder
}


extension FieldProperty: EnumCollectionSchemaReflectable where Value: Collection, Value.Element: CaseIterable & RawRepresentable {
    @discardableResult
    public static func reflectEnumCollectionSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, [Value.Element.RawValue].self, .required)
    }
}

extension OptionalFieldProperty: EnumCollectionSchemaReflectable where Value.WrappedType: Collection, Value.WrappedType.Element: CaseIterable & RawRepresentable {
    @discardableResult
    public static func reflectEnumCollectionSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, [Value.WrappedType.Element.RawValue].self, .required)
    }
}
