//
//  ReflectableExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/27/18.
//

import Foundation
import Vapor
import Fluent
import Runtime
import RuntimeExtensions

extension Model {
    public static var schema: String { "\(self)" }
}
extension SchemaBuilder {
    func intID(auto: Bool = true) -> Self {
        field(.id, .int, .identifier(auto: auto))
    }

    func stringID(auto: Bool = true) -> Self {
        field(.id, .string, .identifier(auto: auto))
    }
}

extension PropertyInfo {
    var fieldName: String {
        var propertyName = name
        if propertyName.starts(with: "_") {
            propertyName = String(propertyName.dropFirst())
        }
        return propertyName
    }


    var fieldKey: FieldKey {
        return FieldKey(fieldName)
    }
}
public extension Model {
    static func schema(for database: Database) -> SchemaBuilder {
        database.schema(schema)
    }

    static func autoMigrate(on database: Database) -> EventLoopFuture<Void> {
        var schema = schema(for: database)
        try? RuntimeExtensions.properties(self).forEach { property in
            schema = schema.reflectSchema(for: property)
        }
        return schema.create()
    }
}

public extension Database {
    func autoMigrate<M: Model>(_ model: M.Type) -> EventLoopFuture<Void> {
        return M.autoMigrate(on: self)
    }
}



public extension FieldKey {
    init(_ string: String) {
        self.init(stringLiteral: string)
    }
}

protocol SchemaReflectable {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder

}

protocol DatabaseSchemaDataTypeReflectable {
    static var databaseSchemaDataType: DatabaseSchema.DataType { get }
}

public extension SchemaBuilder {
    func reflectSchema(for property: PropertyInfo) -> SchemaBuilder {
        let propertyType = property.type

        if let enumSchemaReflectable = propertyType as? EnumSchemaReflectable.Type {
            return enumSchemaReflectable.reflectEnumSchema(with: property.fieldKey, to: self)
        }
        else if let enumCollectionSchemaReflectable = propertyType as? EnumCollectionSchemaReflectable.Type {
            return enumCollectionSchemaReflectable.reflectEnumCollectionSchema(with: property.fieldKey, to: self)
        }
        else if let schemaReflectable = property.type as? SchemaReflectable.Type {
            return schemaReflectable.reflectSchema(with: property.fieldKey, to: self)
        }
        return self
    }
    func reflectSchema(of type: Any.Type,
                       fieldKeyBuilder: (PropertyInfo) -> FieldKey = { FieldKey($0.name) }) -> Self {
        try? RuntimeExtensions.properties(type).forEach { property in
            //            let kind = try property.kind()
            if let schemaReflectable = property.type as? SchemaReflectable.Type {
                schemaReflectable.reflectSchema(with: fieldKeyBuilder(property), to: self)
            }
        }
        print("SCHEMA: \(self.schema)")
        return self
    }
}

public extension DatabaseSchema.DataType {

    static func `enum`<EnumType: CaseIterable>(_ type: EnumType.Type, name: String? = nil) -> DatabaseSchema.DataType {
        return .enum(type.toSchema(name: name))
    }
    static func `enum`<EnumType: CaseIterable>(_ type: EnumType.Type, name: String? = nil) -> DatabaseSchema.DataType.Enum {
        return type.toSchema(name: name)
    }
}

extension TypeInfo {
    func enumDefinition(name: String? = nil) -> DatabaseSchema.DataType.Enum? {
        guard isEnum() else { return nil }
        let name = name ?? self.name
        let cases = cases.map { "\($0.name)"}
        return .init(name: name, cases: cases)
    }
}
public extension CaseIterable {
    static func toSchema(name: String? = nil) -> DatabaseSchema.DataType{
        return .enum(toSchema(name: name))
    }


    static func toSchema(name: String? = nil) -> DatabaseSchema.DataType.Enum {
        let name: String = name ?? String(describing: Self.self)
        let cases = allCases.map { "\($0)"}
        return .init(name: name, cases: cases)
    }
}
public class ReflectionSchemaBuilder {
    static func reflectRawDatabaseSchemaDataType(for type: Any.Type) -> DatabaseSchema.DataType {

        switch type {
        case is Int.Type: return .int
        case is Int8.Type: return .int8
        case is Int16.Type: return .int16
        case is Int32.Type: return .int32
        case is Int64.Type: return .int64
        case is UInt.Type: return .uint
        case is UInt8.Type: return .uint8
        case is UInt16.Type: return .uint16
        case is UInt32.Type: return .uint32
        case is UInt64.Type: return .uint64
        case is Bool.Type: return .bool
        case is String.Type: return .string
        //        case is Time.Type: return .time
        //        case is [Time].Type: return .array(of: .time)
        case is Date.Type: return .datetime
        //        case is Datetime.Type: return .datetime
        //        case is [Datetime].Type: return .array(of: .datetime)
        case is Float.Type: return .float
        case is Double.Type: return .double
        case is Data.Type: return .data
        case is UUID.Type: return .uuid

        //            public static var json: DataType {
        //                .dictionary
        //            }
        //            public static var dictionary: DataType {
        //                .dictionary(of: nil)
        //            }
        //            case dictionary(of: DataType?)

        //            public static var array: DataType {
        //                .array(of: nil)
        //            }
        //            case array(of: DataType?)
        //            case custom(Any)

        default: fatalError()
        }
    }
    static func reflectDatabaseSchemaDataType(for type: Any.Type, defineAsEnum: Bool = false) throws -> DatabaseSchema.DataType {
        let typeInfo = try Runtime.typeInfo(of: type)
        if let elementType = typeInfo.arrayElementType {
            return .array(of: try reflectDatabaseSchemaDataType(for: elementType))
        }
        if defineAsEnum, let enumDefinition = typeInfo.enumDefinition() {
                return .enum(enumDefinition)
        }

        if let valueType = typeInfo.dictionaryValueType {
            guard typeInfo.dictionaryKeyType == String.self else {
                fatalError("Fluent only supports Dictionary types with String keys.")
            }
            return .dictionary(of: try reflectDatabaseSchemaDataType(for: valueType,
                                                                     defineAsEnum: true))
        }
        return reflectRawDatabaseSchemaDataType(for: type)
    }
}

extension TypeInfo {
    func isDictionary() -> Bool {
        mangledName == "Dictionary"
    }
    var dictionaryKeyType: Any.Type? {
        return isDictionary() ? try? genericType(at: 0) : nil
    }

    var dictionaryValueType: Any.Type? {
        return isDictionary() ? try? genericType(at: 1) : nil
    }
    var arrayElementType: Any.Type? {
        return isArray() ? try? genericType(at: 0) : nil
    }


}


public extension DatabaseSchema.DataType {
    init(_ swiftType: Any.Type, defineAsEnum: Bool = false) {
        do {
            self = try ReflectionSchemaBuilder.reflectDatabaseSchemaDataType(for: swiftType, defineAsEnum: defineAsEnum)
        }
        catch {
            fatalError()
        }

    }
}

public extension SchemaBuilder {
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
extension IDProperty: SchemaReflectable {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.self, .identifier(auto: true))
    }
}

extension FieldProperty: SchemaReflectable {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.self, .required)
    }
}

protocol EnumSchemaReflectable {
    static func reflectEnumSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder
}
protocol EnumCollectionSchemaReflectable {
    static func reflectEnumCollectionSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder
}

extension FieldProperty: EnumSchemaReflectable where Value: CaseIterable & RawRepresentable {
    @discardableResult
    static func reflectEnumSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.AllCases.Element.RawValue.self, .required)
    }
}

extension FieldProperty: EnumCollectionSchemaReflectable where Value: Collection, Value.Element: CaseIterable & RawRepresentable {
    @discardableResult
    static func reflectEnumCollectionSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, [Value.Element.RawValue].self, .required)
    }
}

extension OptionalFieldProperty: EnumSchemaReflectable where Value.WrappedType: CaseIterable & RawRepresentable {
    @discardableResult
    static func reflectEnumSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.WrappedType.AllCases.Element.RawValue.self, .required)
    }
}

extension OptionalFieldProperty: EnumCollectionSchemaReflectable where Value.WrappedType: Collection, Value.WrappedType.Element: CaseIterable & RawRepresentable {
    @discardableResult
    static func reflectEnumCollectionSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, [Value.WrappedType.Element.RawValue].self, .required)
    }
}

extension OptionalFieldProperty: SchemaReflectable {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.WrappedType.self)
    }
}

extension EnumProperty: SchemaReflectable {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.self, isEnum: true, .required)
    }
}

extension OptionalEnumProperty: SchemaReflectable {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.WrappedType.self, isEnum: true)
    }
}

public extension FieldKey {
    static func group(_ group: FieldKey, _ field: FieldKey) -> Self {
        return  .string("\(group)_\(field)")
    }
}
extension GroupProperty: SchemaReflectable {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        //MARK: Grouped Fields Schema
//        .field(.group(.group, .stringField), .string, .required)
//        .field(.group(.group, .optionalStringField), .string)
//        .field(.group(.group, .intField), .int, .required)

        return builder.reflectSchema(of: Value.self) { property in
            FieldKey.group(key, property.fieldKey)
        }
    }
}


extension TimestampProperty: SchemaReflectable {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
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

extension OptionalParentProperty: SchemaReflectable {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder
    }
}

extension ChildrenProperty: SchemaReflectable {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder
    }
}

extension OptionalChildProperty: SchemaReflectable {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder
    }
}

extension SiblingsProperty: SchemaReflectable {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder
    }
}


extension Collection {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, .array(of: .init(Element.self)), .required)
    }
}
