//
//  DatabaseDataType+Reflection.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/18/24.
//


import Foundation
import Vapor
import Fluent
import Runtime
import RuntimeExtensions

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