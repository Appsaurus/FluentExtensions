//
//  EnumSchemaReflectable.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/18/24.
//

import Foundation
import Vapor
import Fluent
import Runtime
import RuntimeExtensions

/// A protocol that enables automatic schema reflection for enum types in Fluent models.
///
/// This protocol is primarily used to automatically generate database schema definitions
/// for enum properties, allowing seamless integration of Swift enums with database schemas.
///
/// ## Overview
/// - Provides automatic schema reflection for enum types
/// - Supports both required and optional enum fields
/// - Handles raw representable enums
protocol EnumSchemaReflectable {
    /// Reflects the enum's schema structure into a database schema builder.
    ///
    /// - Parameters:
    ///   - key: The field key that will be used in the database schema
    ///   - builder: The schema builder to add the enum field to
    /// - Returns: The modified schema builder with the enum field added
    static func reflectEnumSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder
}

// MARK: - Required Enum Fields
extension FieldProperty: EnumSchemaReflectable where Value: CaseIterable & RawRepresentable {
    @discardableResult
    public static func reflectEnumSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        // Create a required field using the enum's raw value type
        return builder.field(key, Value.AllCases.Element.RawValue.self, .required)
    }
}

// MARK: - Optional Enum Fields
extension OptionalFieldProperty: EnumSchemaReflectable where Value.WrappedType: CaseIterable & RawRepresentable {
    @discardableResult
    public static func reflectEnumSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        // Create an optional field using the enum's raw value type
        return builder.field(key, Value.WrappedType.AllCases.Element.RawValue.self, .required)
    }
}

// MARK: - Database Schema Type Extensions
public extension DatabaseSchema.DataType {
    /// Creates a database enum type from a CaseIterable enum.
    ///
    /// - Parameters:
    ///   - type: The enum type to create a database type for
    ///   - name: Optional custom name for the enum type. Defaults to the type name if nil
    /// - Returns: A DatabaseSchema.DataType representing the enum
    static func `enum`<EnumType: CaseIterable>(_ type: EnumType.Type, name: String? = nil) -> DatabaseSchema.DataType {
        return .enum(type.toSchema(name: name))
    }

    /// Creates a database enum definition from a CaseIterable enum.
    ///
    /// - Parameters:
    ///   - type: The enum type to create a definition for
    ///   - name: Optional custom name for the enum. Defaults to the type name if nil
    /// - Returns: A DatabaseSchema.DataType.Enum representing the enum definition
    static func `enum`<EnumType: CaseIterable>(_ type: EnumType.Type, name: String? = nil) -> DatabaseSchema.DataType.Enum {
        return type.toSchema(name: name)
    }
}

// MARK: - Runtime Type Info Extensions
public extension TypeInfo {
    /// Generates a database enum definition from runtime type information.
    ///
    /// - Parameter name: Optional custom name for the enum. Defaults to the field name if nil
    /// - Returns: Optional DatabaseSchema.DataType.Enum if the type is an enum, nil otherwise
    func enumDefinition(name: String? = nil) -> DatabaseSchema.DataType.Enum? {
        guard isEnum else { return nil }
        let name = name ?? self.fieldName
        let cases = cases.map { "\($0.name)"}
        return .init(name: name, cases: cases)
    }
}

// MARK: - CaseIterable Extensions
public extension CaseIterable {
    /// Converts the enum type to a database schema data type.
    ///
    /// - Parameter name: Optional custom name for the enum type
    /// - Returns: A DatabaseSchema.DataType representing the enum
    static func toSchema(name: String? = nil) -> DatabaseSchema.DataType {
        return .enum(toSchema(name: name))
    }

    /// Converts the enum type to a database schema enum definition.
    ///
    /// - Parameter name: Optional custom name for the enum
    /// - Returns: A DatabaseSchema.DataType.Enum representing the enum definition
    static func toSchema(name: String? = nil) -> DatabaseSchema.DataType.Enum {
        let name: String = name ?? String(describing: Self.self)
        let cases = allCases.map { "\($0)"}
        return .init(name: name, cases: cases)
    }
}
