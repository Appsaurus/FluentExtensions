//
//  QueryParameterFilter+Builder.swift
//
//
//  Created by Brian Strobach on 2/13/25.
//

import Fluent
import Codability

public extension QueryParameterFilter {
    class Builder<M: Model> {
        public typealias NestedBuilder = (_ query: QueryBuilder<M>, _ field: String, _ condition: FilterCondition) throws -> DatabaseQuery.Filter?
        public typealias FieldOverride = (_ query: QueryBuilder<M>, _ method: QueryParameterFilter.Method, _ value: AnyCodable) throws -> DatabaseQuery.Filter?
        
        public class Config {
            
            public var nestedBuilders: [String: NestedBuilder]
            public var fieldOverrides: [String: FieldOverride]
            public var fieldKeyMap: [String: FieldKey]
            
            public init(nestedBuilders: [String: NestedBuilder] = [:],
                        fieldOverrides: [String: FieldOverride] = [:],
                        fieldKeyMap: [String: FieldKey] = [:]) {
                self.nestedBuilders = nestedBuilders
                self.fieldOverrides = fieldOverrides
                self.fieldKeyMap = fieldKeyMap
            }
            
        }
        
        public let query: QueryBuilder<M>
        public let schema: String
        public let config: Config
        
        public init(_ query: QueryBuilder<M>, schema: String? = nil, config: Config = Config()) {
            self.query = query
            self.schema = schema ?? M.schemaOrAlias
            self.config = config
        }
        
        public func addNestedQueryBuilder(
            for field: String,
            builder: @escaping NestedBuilder
        ) {
            config.nestedBuilders[field] = builder
        }
        
        public func addWhereOverride(
            for field: String,
            override: @escaping FieldOverride
        ) {
            config.fieldOverrides[field] = override
        }
    }
}
