//
//  SchemaReflectable.swift
//  
//
//  Created by Brian Strobach on 8/30/21.
//

import Foundation
import Vapor
import Fluent
import Runtime
import RuntimeExtensions


extension Model {
    public typealias Migration = AutoMigration<Self>
}
open class AutoMigration<M: Model>: ReflectionMigration {
    public typealias ModelType = M
    public required init(){}

    open var config: ReflectionConfiguration {
        defaultConfiguration
    }

    open var fieldKeyMap: [String: FieldKey] { [:] }

    open func override(schema: SchemaBuilder, property: PropertyInfo) -> Bool { false }

    @discardableResult
    open func customize(schema: SchemaBuilder) -> SchemaBuilder {
        return schema
    }

    open func prepare(on database: Database) -> EventLoopFuture<Void> {
        let schema = database.reflectSchema(ModelType.self, configuration: config)
        return customize(schema: schema).create()
    }

    open func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(ModelType.schema).delete()
    }
}

open class ReflectionConfiguration {
    open var fieldKeyMap: [String: FieldKey]
    open var override: ((SchemaBuilder, PropertyInfo) -> Bool)

    public init(fieldKeyMap: [String : FieldKey] = [:],
                  overrides: @escaping ((SchemaBuilder, PropertyInfo) -> Bool) = { _ , _ in false }) {
        self.fieldKeyMap = fieldKeyMap
        self.override = overrides
    }
}

public protocol ReflectionMigration: Migration  {
    associatedtype ModelType: Model
    var config: ReflectionConfiguration { get }
    func customize(schema: SchemaBuilder) -> SchemaBuilder
    var fieldKeyMap: [String: FieldKey] { get}
    func override(schema: SchemaBuilder, property: PropertyInfo) -> Bool
}

public extension ReflectionMigration {
    fileprivate var defaultConfiguration: ReflectionConfiguration {
        ReflectionConfiguration(fieldKeyMap: fieldKeyMap, overrides: override(schema:property:))
    }
    var config: ReflectionConfiguration {
        defaultConfiguration
    }

    var fieldKeyMap: [String: FieldKey] { [:] }

    func override(schema: SchemaBuilder, property: PropertyInfo) -> Bool { false }

    @discardableResult
    func customize(schema: SchemaBuilder) -> SchemaBuilder {
        return schema
    }

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let schema = database.reflectSchema(ModelType.self, configuration: config)
        return customize(schema: schema).create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(ModelType.schema).delete()
    }
}

public extension ReflectionMigration where Self: Model {
    typealias ModelType = Self
}

public extension Database {
    func reflectSchema<M: Model>(_ model: M.Type, configuration: ReflectionConfiguration? = nil) -> SchemaBuilder {
        return M.reflectSchema(on: self, configuration: configuration)
    }

    func autoMigrate<M: Model>(_ model: M.Type) -> EventLoopFuture<Void> {
        return M.autoMigrate(on: self)
    }
}

public extension Model {
    static func reflectSchema(on database: Database, configuration: ReflectionConfiguration? = nil) -> SchemaBuilder {
        let schema = schema(for: database)
        var properties: [PropertyInfo] = []
        if let reflectedProperties = try? RuntimeExtensions.properties(self) {
            properties = reflectedProperties
        }
        for property in properties {
            guard configuration?.override(schema, property) != true else {
                continue
            }

            schema.reflectSchema(for: property) { property in
                let fieldKey = configuration?.fieldKeyMap[property.fieldName]
                return fieldKey ?? FieldKey.reflectionBuilder(property)
            }
        }
        return schema
    }
    static func autoMigrate(on database: Database) -> EventLoopFuture<Void> {
        return reflectSchema(on: database).create()
    }
}

public extension FieldKey {
    static var reflectionBuilder: (PropertyInfo) -> FieldKey = { property in
        return property.fieldKey
    }
}
public extension SchemaBuilder {
    @discardableResult
    func    reflectSchema(for property: PropertyInfo,
                       fieldKeyBuilder: (PropertyInfo) -> FieldKey = FieldKey.reflectionBuilder) -> SchemaBuilder {
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
    func reflectSchema(of type: Any.Type,
                       fieldKeyBuilder: (PropertyInfo) -> FieldKey = FieldKey.reflectionBuilder) -> Self {
        try? RuntimeExtensions.properties(type).forEach { property in
            reflectSchema(for: property, fieldKeyBuilder: fieldKeyBuilder)
        }
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

public extension TypeInfo {
    func enumDefinition(name: String? = nil) -> DatabaseSchema.DataType.Enum? {
        guard isEnum else { return nil }
        let name = name ?? self.fieldName
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

public protocol DatabaseSchemaDataTypeProviding {
    static var dataType: DatabaseSchema.DataType { get }
}

extension Int: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .int
    }
}
extension Int8: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .int8
    }
}
extension Int16: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .int16
    }
}
extension Int32: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .int32
    }
}
extension Int64: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .int64
    }
}
extension UInt: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .uint
    }
}
extension UInt8: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .uint8
    }
}
extension UInt16: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .uint16
    }
}
extension UInt32: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .uint32

    }
}
extension UInt64: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .uint64
    }
}
extension Bool: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .bool
    }
}
extension String: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .string
    }
}
extension Date: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .datetime
    }
}
extension Float: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .float
    }
}
extension Double: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .double
    }
}
extension Data: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .data
    }
}
extension UUID: DatabaseSchemaDataTypeProviding {
    public static var dataType: DatabaseSchema.DataType {
        .uuid
    }
}
// Might be able to cut down on some reflection, but not sure how to handle enum elements yet.
//extension Array: DatabaseSchemaDataTypeProviding where Element: DatabaseSchemaDataTypeProviding {
//    public static var dataType: DatabaseSchema.DataType {
//        .array(of: Element.dataType)
//    }
//}
//
//extension Dictionary: DatabaseSchemaDataTypeProviding where Key == String, Value: DatabaseSchemaDataTypeProviding {
//    public static var dataType: DatabaseSchema.DataType {
//        .dictionary(of: Value.dataType)
//    }
//}
//
//extension Dictionary where Key == String, Value: CaseIterable & RawRepresentable, Value.RawValue: DatabaseSchemaDataTypeProviding {
//    public static var dataType: DatabaseSchema.DataType {
//        .dictionary(of: Value.RawValue.dataType)
//    }
//}


public extension DatabaseSchema.DataType {
    init(_ swiftType: Any.Type, defineAsEnum: Bool = false) {
        do {
            self = try Self.reflect(for: swiftType, defineAsEnum: defineAsEnum)
        }
        catch {
            fatalError()
        }
    }

    static func reflected(for type: Any.Type) -> DatabaseSchema.DataType {
        if let provider = type as? DatabaseSchemaDataTypeProviding.Type {
            return provider.dataType
        }
        fatalError("\(type) does not implement DatabaseSchemaDataTypeProviding.")
    }

    static func reflect(for type: Any.Type, defineAsEnum: Bool = false) throws -> DatabaseSchema.DataType {
        let typeInfo = try Runtime.typeInfo(of: type)
        if let elementType = typeInfo.arrayElementType {
            return .array(of: try reflect(for: elementType, defineAsEnum: true))
        }

        if defineAsEnum, let enumDefinition = typeInfo.enumDefinition() {
            return .enum(enumDefinition)
        }

        if let valueType = typeInfo.dictionaryValueType {
            guard typeInfo.dictionaryKeyType == String.self else {
                fatalError("Fluent only supports Dictionary types with String keys.")
            }
            return .dictionary(of: try reflect(for: valueType, defineAsEnum: true))
        }

        return reflected(for: type)
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


//MARK: SchemaReflectable

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


extension ParentProperty: SchemaReflectable {

    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder
            .field(key, .init(To.IDValue.self), .required)
            .foreignKey(key, references: To.schema, To.ID<To.IDValue>().key)
    }
}

extension OptionalParentProperty: SchemaReflectable {
    @discardableResult
    public static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder
            .field(key, .init(To.IDValue.self))
            .foreignKey(key, references: To.schema, To.ID<To.IDValue>().key)
    }
}
//
//public extension ChildrenProperty: SchemaReflectable {
//    @discardableResult
//    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
//        return builder//No schema required
//    }
//}
//
//public extension OptionalChildProperty: SchemaReflectable {
//    @discardableResult
//    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
//        return builder//No schema required
//    }
//}
//
//public extension SiblingsProperty: SchemaReflectable {
//    @discardableResult
//    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
//        return builder//No schema required
//    }
//}


public extension Collection {
    @discardableResult
    static func reflectSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, .array(of: .init(Element.self)), .required)
    }
}


//MARK: EnumSchemaReflectable

protocol EnumSchemaReflectable {
    static func reflectEnumSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder
}

extension FieldProperty: EnumSchemaReflectable where Value: CaseIterable & RawRepresentable {
    @discardableResult
    public static func reflectEnumSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.AllCases.Element.RawValue.self, .required)
    }
}

extension OptionalFieldProperty: EnumSchemaReflectable where Value.WrappedType: CaseIterable & RawRepresentable {
    @discardableResult
    public static func reflectEnumSchema(with key: FieldKey, to builder: SchemaBuilder) -> SchemaBuilder {
        return builder.field(key, Value.WrappedType.AllCases.Element.RawValue.self, .required)
    }
}

//MARK: EnumCollectionSchemaReflectable

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
