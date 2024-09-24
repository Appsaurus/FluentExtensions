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
