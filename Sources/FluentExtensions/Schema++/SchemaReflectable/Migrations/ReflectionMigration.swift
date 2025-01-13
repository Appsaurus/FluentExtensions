//
//  ReflectionMigration.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/18/24.
//

import Foundation
import Vapor
import Fluent
import Runtime
import RuntimeExtensions


public typealias ReflectedSchemaProperty = PropertyInfo

open class ReflectionConfiguration {
    open var fieldKeyMap: [String: FieldKey]
    open var override: ((SchemaBuilder, ReflectedSchemaProperty) -> Bool)
    
    public init(fieldKeyMap: [String : FieldKey] = [:],
                overrides: @escaping ((SchemaBuilder, ReflectedSchemaProperty) -> Bool) = { _ , _ in false }) {
        self.fieldKeyMap = fieldKeyMap
        self.override = overrides
    }
}

public protocol ReflectionMigration: AsyncMigration  {
    associatedtype ModelType: Model
    var config: ReflectionConfiguration { get }
    func customize(schema: SchemaBuilder) -> SchemaBuilder
    var fieldKeyMap: [String: FieldKey] { get}
    func override(schema: SchemaBuilder, property: ReflectedSchemaProperty) -> Bool
}

extension ReflectionMigration {
    var defaultConfiguration: ReflectionConfiguration {
        ReflectionConfiguration(fieldKeyMap: fieldKeyMap, overrides: override(schema:property:))
    }
}

public extension ReflectionMigration {
    var config: ReflectionConfiguration {
        defaultConfiguration
    }
    
    var fieldKeyMap: [String: FieldKey] { [:] }
    
    func override(schema: SchemaBuilder, property: ReflectedSchemaProperty) -> Bool { false }
    
    @discardableResult
    func customize(schema: SchemaBuilder) -> SchemaBuilder {
        return schema
    }
    
    func prepare(on database: Database) async throws {
        let schema = database.reflectSchema(ModelType.self, configuration: config)
        try await customize(schema: schema).create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(ModelType.schema).delete()
    }
}

public extension Database {
    func reflectSchema<M: Model>(_ model: M.Type, configuration: ReflectionConfiguration? = nil) -> SchemaBuilder {
        return M.reflectSchema(on: self, configuration: configuration)
    }
    
    func autoMigrate<M: Model>(_ model: M.Type) async throws {
        try await M.autoMigrate(on: self)
    }
}
