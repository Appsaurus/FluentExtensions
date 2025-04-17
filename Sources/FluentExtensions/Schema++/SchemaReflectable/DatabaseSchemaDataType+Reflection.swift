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

extension DatabaseSchema.DataType {
    /// Creates a database schema data type by reflecting on a Swift type.
    ///
    /// This initializer uses runtime reflection to determine the appropriate database schema data type
    /// for a given Swift type. It can handle arrays, enums, and dictionary types, converting them into
    /// their corresponding database representations.
    ///
    /// - Parameters:
    ///   - swiftType: The Swift type to reflect upon.
    ///   - defineAsEnum: A boolean flag indicating whether the type should be treated as an enum.
    ///     Defaults to `false`.
    /// - Note: Will fatal error if reflection fails or if type is not supported.
    public init(_ swiftType: Any.Type, defineAsEnum: Bool = false) {
        do {
            self = try Self.reflect(for: swiftType, defineAsEnum: defineAsEnum)
        }
        catch {
            fatalError()
        }
    }

    /// Returns the database schema data type for types conforming to `DatabaseSchemaDataTypeProviding`.
    ///
    /// - Parameter type: The type to reflect upon, must conform to `DatabaseSchemaDataTypeProviding`.
    /// - Returns: The corresponding database schema data type.
    /// - Note: Will fatal error if the type does not implement `DatabaseSchemaDataTypeProviding`.
    static func reflected(for type: Any.Type) -> DatabaseSchema.DataType {
        if let provider = type as? DatabaseSchemaDataTypeProviding.Type {
            return provider.dataType
        }
        fatalError("\(type) does not implement DatabaseSchemaDataTypeProviding.")
    }

    /// Reflects on a Swift type to determine its corresponding database schema data type.
    ///
    /// This method handles complex type reflection including:
    /// - Array types (converts to database array type)
    /// - Enum types (when defineAsEnum is true)
    /// - Dictionary types (must have String keys)
    ///
    /// - Parameters:
    ///   - type: The Swift type to reflect upon.
    ///   - defineAsEnum: A boolean flag indicating whether the type should be treated as an enum.
    ///     Defaults to `false`.
    /// - Returns: The corresponding database schema data type.
    /// - Throws: Runtime reflection errors.
    /// - Note: Will fatal error if dictionary has non-String keys.
    static func reflect(for type: Any.Type, defineAsEnum: Bool = false) throws -> DatabaseSchema.DataType {
        let typeInfo = try Runtime.typeInfo(of: type)
        
        // Handle array types
        if let elementType = typeInfo.arrayElementType {
            return .array(of: try reflect(for: elementType, defineAsEnum: true))
        }

        // Handle enum types
        if defineAsEnum, let enumDefinition = typeInfo.enumDefinition() {
            return .enum(enumDefinition)
        }

        // Handle dictionary types
        if let valueType = typeInfo.dictionaryValueType {
            guard typeInfo.dictionaryKeyType == String.self else {
                fatalError("Fluent only supports Dictionary types with String keys.")
            }
            return .dictionary(of: try reflect(for: valueType, defineAsEnum: true))
        }

        return reflected(for: type)
    }
}
