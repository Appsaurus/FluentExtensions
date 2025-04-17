//
//  QueryParameterFilter+Builder.swift
//
//
//  Created by Brian Strobach on 2/13/25.
//

import Fluent
import Codability

/// Extension providing filter building capabilities for QueryParameterFilter
public extension QueryParameterFilter {
    /// A builder class for constructing query filters with support for nested queries and field overrides
    class Builder<M: Model> {
        /// Type alias for nested builder closure that constructs database filters
        public typealias NestedBuilder = (_ query: QueryBuilder<M>, _ field: String, _ condition: FilterCondition) throws -> DatabaseQuery.Filter?
        
        /// Type alias for field override closure that constructs custom database filters
        public typealias FieldOverride = (_ query: QueryBuilder<M>, _ method: QueryParameterFilter.Method, _ value: AnyCodable) throws -> DatabaseQuery.Filter?
        
        /// Configuration container for the Builder
        public class Config {
            /// Dictionary mapping field names to nested builder closures
            public var nestedBuilders: [String: NestedBuilder]
            
            /// Dictionary mapping field names to field override closures
            public var fieldOverrides: [String: FieldOverride]
            
            /// Dictionary mapping field names to database field keys
            public var fieldKeyMap: [String: FieldKey]
            
            /// Creates a new configuration instance
            /// - Parameters:
            ///   - nestedBuilders: Dictionary of nested builder closures
            ///   - fieldOverrides: Dictionary of field override closures
            ///   - fieldKeyMap: Dictionary mapping field names to database field keys
            public init(nestedBuilders: [String: NestedBuilder] = [:],
                       fieldOverrides: [String: FieldOverride] = [:],
                       fieldKeyMap: [String: FieldKey] = [:]) {
                self.nestedBuilders = nestedBuilders
                self.fieldOverrides = fieldOverrides
                self.fieldKeyMap = fieldKeyMap
            }
        }
        
        /// The underlying query builder instance
        public let query: QueryBuilder<M>
        
        /// The database schema name
        public let schema: String
        
        /// The builder configuration
        public let config: Config
        
        /// Creates a new Builder instance
        /// - Parameters:
        ///   - query: The query builder to extend
        ///   - schema: Optional schema name, defaults to model's schema
        ///   - config: Builder configuration
        public init(_ query: QueryBuilder<M>, schema: String? = nil, config: Config = Config()) {
            self.query = query
            self.schema = schema ?? M.schemaOrAlias
            self.config = config
        }
        
        /// Adds a nested query builder for a specific field
        /// - Parameters:
        ///   - field: The field name to associate with the builder
        ///   - builder: The nested builder closure
        public func addNestedQueryBuilder(
            for field: String,
            builder: @escaping NestedBuilder
        ) {
            config.nestedBuilders[field] = builder
        }
        
        /// Adds a field override for custom filter behavior
        /// - Parameters:
        ///   - field: The field name to override
        ///   - override: The override closure
        public func addWhereOverride(
            for field: String,
            override: @escaping FieldOverride
        ) {
            config.fieldOverrides[field] = override
        }
    }
}
