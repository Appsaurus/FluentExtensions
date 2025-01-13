//
//  SchemaReflectable.swift
//
//
//  Created by Brian Strobach on 8/30/21.
//

import Foundation
import Vapor
import Fluent

protocol SchemaReflectable {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder
    
}

extension IDProperty: SchemaReflectable {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.self, .identifier(auto: true))
    }
}

extension FieldProperty: SchemaReflectable {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.self, .required)
    }
}

extension OptionalFieldProperty: SchemaReflectable {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.WrappedType.self)
    }
}

extension EnumProperty: SchemaReflectable {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.self, isEnum: true, .required)
    }
}

extension OptionalEnumProperty: SchemaReflectable {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.WrappedType.self, isEnum: true)
    }
}

extension TimestampProperty: SchemaReflectable {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        switch Format.self {
        case is ISO8601TimestampFormat.Type:
            return builder.field(key, String.self)
        case is DefaultTimestampFormat.Type:
            return builder.field(key, Date.self)
        case is UnixTimestampFormat.Type:
            return builder.field(key, Double.self)
        default: fatalError()
        }
    }
}

extension ParentProperty: SchemaReflectable where To.IDValue == UUID {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder
            .field(key, .init(To.IDValue.self), .required)
            .foreignKey(key, references: To.schema, To.ID<To.IDValue>(key: .id).key)
    }
}

extension OptionalParentProperty: SchemaReflectable where To.IDValue == UUID {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder
            .field(key, .init(To.IDValue.self))
            .foreignKey(key, references: To.schema, To.ID<To.IDValue>(key: .id).key)
    }
}

public extension FieldKey {
    static func group(_ group: FieldKey, _ field: FieldKey) -> Self {
        return  .string("\(group)_\(field)")
    }
}
extension GroupProperty: SchemaReflectable {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        //MARK: Grouped Fields Schema
        //        .field(.group(.group, .stringField), .string, .required)
        //        .field(.group(.group, .optionalStringField), .string)
        //        .field(.group(.group, .intField), .int, .required)
        
        return builder.reflectSchema(of: Value.self) { property in
            FieldKey.group(key, property.fieldKey)
        }
    }
}

public extension Collection {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, .array(of: .init(Element.self)), .required)
    }
}

