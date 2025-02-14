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
        public class Config {
            
            public var nestedBuilders: [String: (_ query: QueryBuilder<M>, _ field: String, _ condition: FilterCondition) throws -> DatabaseQuery.Filter?]
            public var fieldOverrides: [String: (_ method: QueryParameterFilter.Method, _ value: AnyCodable) throws -> DatabaseQuery.Filter?]
            
            public init(nestedBuilders: [String : (QueryBuilder<M>, String, FilterCondition) throws -> DatabaseQuery.Filter?] = [:],
                        fieldOverrides: [String : (QueryParameterFilter.Method, AnyCodable) throws -> DatabaseQuery.Filter?] = [:]) {
                self.nestedBuilders = nestedBuilders
                self.fieldOverrides =                         fieldOverrides
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
            builder: @escaping (_ query: QueryBuilder<M>, _ field: String, _ condition: FilterCondition) throws -> DatabaseQuery.Filter?
        ) {
            config.nestedBuilders[field] = builder
        }
        
        public func addWhereOverride(
            for field: String,
            override: @escaping (_ method: QueryParameterFilter.Method, _ value: AnyCodable) throws -> DatabaseQuery.Filter?
        ) {
            config.fieldOverrides[field] = override
        }
    }
}
