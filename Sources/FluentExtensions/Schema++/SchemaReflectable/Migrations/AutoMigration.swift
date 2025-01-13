//
//  AutoMigration.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/18/24.
//


import Foundation
import Vapor
import Fluent
import Runtime
import RuntimeExtensions

open class AutoMigration<M: Model>: ReflectionMigration, @unchecked Sendable {
    public typealias ModelType = M
    public required init(){}
    
    open var config: ReflectionConfiguration {
        defaultConfiguration
    }
    
    open var fieldKeyMap: [String: FieldKey] { [:] }
    
    open func override(schema: SchemaBuilder, property: ReflectedSchemaProperty) -> Bool { false }
    
    @discardableResult
    open func customize(schema: SchemaBuilder) -> SchemaBuilder {
        return schema
    }
    
    open func prepare(on database: Database) async throws {
        let schema = database.reflectSchema(ModelType.self, configuration: config)
        return try await customize(schema: schema).create()
    }
    
    open func revert(on database: Database) async throws {
        try await database.schema(ModelType.schema).delete()
    }
}

public extension Model {
    
    static func autoMigrate(on database: Database) async throws {
        try await reflectSchema(on: database).create()
    }
    
    static func reflectSchema(on database: Database,
                              configuration: ReflectionConfiguration? = nil) -> SchemaBuilder {
        let schema = schema(for: database)
        guard let properties = try? reflectedSchemaProperties() else {
            return schema
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
}
