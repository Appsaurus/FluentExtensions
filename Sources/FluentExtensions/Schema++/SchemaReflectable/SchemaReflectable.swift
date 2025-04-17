//
//  SchemaReflectable.swift
//
//
//  Created by Brian Strobach on 8/30/21.
//

import Foundation
import Vapor
import Fluent

/// A protocol that enables automatic schema reflection for Fluent model properties.
///
/// Schema reflection allows for automatic database schema generation based on Swift property types.
/// This protocol standardizes how different property types contribute to the database schema.
///
/// - Important: All property types that can be stored in a database should conform to this protocol.
protocol SchemaReflectable {
    /// Reflects the schema requirements for this property type into the provided schema builder.
    /// - Parameters:
    ///   - key: The field key under which this property should be stored in the database.
    ///   - builder: The schema builder to configure with this property's requirements.
    /// - Returns: The modified schema builder.
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder
}

// MARK: - ID Property
extension IDProperty: SchemaReflectable {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.self, .identifier(auto: true))
    }
}

// MARK: - Field Property
extension FieldProperty: SchemaReflectable {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.self, .required)
    }
}

// MARK: - Optional Field Property
extension OptionalFieldProperty: SchemaReflectable {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.WrappedType.self)
    }
}

// MARK: - Enum Property
extension EnumProperty: SchemaReflectable {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.self, isEnum: true, .required)
    }
}

// MARK: - Optional Enum Property
extension OptionalEnumProperty: SchemaReflectable {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.WrappedType.self, isEnum: true)
    }
}

// MARK: - Timestamp Property
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

// MARK: - Parent Property
/// Parent property schema reflection for UUID-based relationships
extension ParentProperty: SchemaReflectable where To.IDValue == UUID {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder
            .field(key, .init(To.IDValue.self), .required)
            .foreignKey(key, references: To.schema, To.ID<To.IDValue>(key: .id).key)
    }
}

// MARK: - Optional Parent Property
/// Optional parent property schema reflection for UUID-based relationships
extension OptionalParentProperty: SchemaReflectable where To.IDValue == UUID {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder
            .field(key, .init(To.IDValue.self))
            .foreignKey(key, references: To.schema, To.ID<To.IDValue>(key: .id).key)
    }
}

public extension FieldKey {
    /// Creates a composite field key by combining a group key with a field key
    /// - Parameters:
    ///   - group: The group identifier
    ///   - field: The field identifier within the group
    /// - Returns: A new field key combining the group and field
    static func group(_ group: FieldKey, _ field: FieldKey) -> Self {
        return .string("\(group)_\(field)")
    }
}

// MARK: - Group Property
extension GroupProperty: SchemaReflectable {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.reflectSchema(of: Value.self) { property in
            FieldKey.group(key, property.fieldKey)
        }
    }
}

// MARK: - Collection Property
public extension Collection {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, .array(of: .init(Element.self)), .required)
    }
}
