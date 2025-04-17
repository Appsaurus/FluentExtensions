//
//  FlatQueryParametersFilter.swift
//
//  Created by Brian Strobach on 2/13/25.
//

import Vapor
import Foundation
import Fluent
import Codability

/// Extends QueryBuilder to provide filtering capabilities based on URL query parameters
public extension QueryBuilder {
    
    /// Filters the query based on all model properties using request query parameters
    /// - Parameter request: The incoming HTTP request containing query parameters
    /// - Returns: The filtered query builder
    /// - Throws: Any errors that occur during filtering
    @discardableResult
    func filterByQueryParameters(request: Request) throws -> QueryBuilder<Model> {
        var query = self
        for property in try Model.reflectedSchemaProperties() {
            query = try filter(property, on: request)
        }
        return query
    }
    
    /// Filters the query based on a specific reflected schema property
    /// - Parameters:
    ///   - property: The reflected schema property to filter on
    ///   - queryParameterKey: Optional custom query parameter key
    ///   - request: The incoming HTTP request
    /// - Returns: The filtered query builder
    /// - Throws: Any errors that occur during filtering
    @discardableResult
    func filter(_ property: ReflectedSchemaProperty,
                withQueryValueAt queryParameterKey: String? = nil,
                on request: Request) throws -> QueryBuilder<Model> {
        var query = self
        let propertyName: String = property.fieldName
        let queryParameterKey = queryParameterKey ?? propertyName
        if let filterable = property.type as? AnyProperty.Type {
            query = try filter(propertyName, withQueryValueAt: queryParameterKey, as: filterable.anyValueType, on: request)
        }
        return query
    }
    
    /// Filters the query based on a coding key path
    /// - Parameters:
    ///   - keyPath: The coding key path to filter on
    ///   - queryParameterKey: The query parameter key to use
    ///   - queryValueType: Optional type of the query value
    ///   - request: The incoming HTTP request
    /// - Returns: The filtered query builder
    /// - Throws: Any errors that occur during filtering
    @discardableResult
    func filter(_ keyPath: CodingKeyRepresentable,
                withQueryValueAt queryParameterKey: String,
                as queryValueType: Any.Type? = nil,
                on request: Request) throws -> QueryBuilder<Model> {
        var query = self
        if let queryFilter = try? request.query.parseFilter(for: Model.self,
                                                            at: keyPath,
                                                            withQueryValueAt: queryParameterKey,
                                                            as: queryValueType) {
            query = try filter(queryFilter)
        }
        return query
    }
}

/// Additional filtering capabilities for QueryBuilder
extension QueryBuilder {
    
    /// Applies a query parameter filter to a specific key path
    /// - Parameters:
    ///   - keyPath: The key path to filter on
    ///   - queryParameterFilter: The filter to apply
    /// - Returns: The filtered query builder
    /// - Throws: Any errors that occur during filtering
    @discardableResult
    func filter<V: QueryableProperty>(keyPath: KeyPath<Model,V>,
                                      queryParameterFilter: QueryParameterFilter) throws -> QueryBuilder<Model> {
        queryParameterFilter.name = keyPath.propertyName
        return try filter(queryParameterFilter)
    }
    
    /// Filters based on a key path and query parameter
    /// - Parameters:
    ///   - keyPath: The key path to filter on
    ///   - queryParameterKey: Optional custom query parameter key
    ///   - req: The incoming HTTP request
    /// - Returns: The filtered query builder
    /// - Throws: Any errors that occur during filtering
    @discardableResult
    func filter<V: QueryableProperty>(keyPath: KeyPath<Model,V>,
                                      withQueryValueAt queryParameterKey: String? = nil,
                                      on req: Request) throws -> QueryBuilder<Model> {
        guard let queryFilter = try req.query.parseFilter(for: keyPath, withQueryValueAt: queryParameterKey) else {
            return self
        }
        return try filter(queryFilter)
    }
    
    /// Filters based on a string key path
    /// - Parameters:
    ///   - keyPath: The string key path to filter on
    ///   - queryParameterKey: Optional custom query parameter key
    ///   - req: The incoming HTTP request
    /// - Returns: The filtered query builder
    /// - Throws: Any errors that occur during filtering
    @discardableResult
    func filter(_ keyPath: String,
                withQueryValueAt queryParameterKey: String? = nil,
                on req: Request) throws -> QueryBuilder<Model> {
        guard let queryFilter = try req.query.parseFilter(for: Model.self,
                                                          at: keyPath,
                                                          withQueryValueAt: queryParameterKey) else {
            return self
        }
        return try filter(queryFilter)
    }
}

/// Defines parameter value types and methods for query parameter filtering
public extension QueryParameterFilter.Method {
    enum ParameterValueType {
        case single
        case multiple
        case range
    }
    
    /// Determines the expected value type based on the filter method
    var expectedValueType: ParameterValueType {
        if Self.arrayValues.contains(self) {
            return .multiple
        }
        if Self.rangeValues.contains(self) {
            return .range
        }
        return .single
    }
    
    /// Filter methods that expect array values
    static var arrayValues: [QueryParameterFilter.Method] {
        return [.arrIncludesAll,
                .arrIncludesSome,
                .equalsAny
        ]
    }
    
    /// Filter methods that expect range values
    static var rangeValues: [QueryParameterFilter.Method] {
        return [.between,
                .betweenInclusive,
                .inNumberRange
        ]
    }
}

/// Represents a range value in query parameters
public struct QueryParameterRangeValue {
    var lowerBound: String
    var upperBound: String
}

fileprivate extension String {
    /// Converts a string to a range value
    /// - Throws: QueryParameterFilterError if the string format is invalid
    /// - Returns: A QueryParameterRangeValue
    func toRange() throws -> QueryParameterRangeValue {
        let cleaned = self.trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        
        let components = cleaned.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        guard components.count == 2 else {
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
        
        return QueryParameterRangeValue(lowerBound: components[0], upperBound: components[1])
    }
}

extension QueryParameterFilter {
    /// Creates a new QueryParameterFilter from URL query parameters
    /// - Parameters:
    ///   - schema: The schema type
    ///   - fieldName: The field name to filter on
    ///   - queryParameterKey: The query parameter key
    ///   - queryValueType: Optional type of the query value
    ///   - queryContainer: The URL query container
    /// - Throws: Any errors that occur during filter creation
    public convenience init(schema: Schema.Type,
                            fieldName: String,
                            withQueryValueAt queryParameterKey: String,
                            as queryValueType: Any.Type? = nil,
                            from queryContainer: URLQueryContainer) throws {
        
        let decoder = URLEncodedFormDecoder()
        
        guard let config = queryContainer[String.self, at: queryParameterKey] else {
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
        
        let filterConfig = try config.toFilterConfig()
        
        let method = filterConfig.method
        let value = filterConfig.value
        
        var filterValue: QueryParameterFilter.Value<String>
        
        switch method.expectedValueType {
        case .single:
            let str = "\(queryParameterKey)=\(value)"
            filterValue = try .single(decoder.decode(SingleValueDecoder.self, from: str).get(at: [queryParameterKey.codingKey]))
        case .multiple:
            let str = value.components(separatedBy: ",").map { "\(queryParameterKey)[]=\($0)" }.joined(separator: "&")
            filterValue = try .multiple(decoder.decode(SingleValueDecoder.self, from: str).get(at: [queryParameterKey.codingKey]))
        case .range:
            let rangeValue: QueryParameterRangeValue = try value.toRange()
            filterValue = .range(rangeValue)
        }
        
        self.init(schema: schema,
                  name: fieldName,
                  method: method,
                  value: filterValue,
                  queryValueType: queryValueType)
    }
}

public extension URLQueryContainer {
    
    /// Parses a filter for a specific key path
    func parseFilter<V: QueryableProperty, M: Model>(for keyPath: KeyPath<M,V>,
                                                     withQueryValueAt queryParameterKey: String? = nil,
                                                     as queryValueType: Any.Type? = nil) throws -> QueryParameterFilter? {
        try parseFilter(for: M.self,
                        at: keyPath.codingKeys,
                        withQueryValueAt: queryParameterKey,
                        as: queryValueType ?? V.self.Value)
    }
    
    /// Parses a filter for a variadic list of coding keys
    func parseFilter(for schema: Schema.Type,
                     at keyPath: CodingKeyRepresentable...,
                     withQueryValueAt queryParameterKey: String? = nil,
                     as queryValueType: Any.Type? = nil) throws -> QueryParameterFilter? {
        try parseFilter(for: schema, at: keyPath, withQueryValueAt: queryParameterKey, as: queryValueType)
    }
    
    /// Parses a filter for an array of coding keys
    func parseFilter(for schema: Schema.Type,
                     at keyPath: [CodingKeyRepresentable],
                     withQueryValueAt queryParameterKey: String? = nil,
                     as queryValueType: Any.Type? = nil) throws -> QueryParameterFilter? {
        let fieldName = keyPath.map({$0.codingKey.stringValue}).joined(separator: ".")
        return try QueryParameterFilter(schema: schema,
                                        fieldName: fieldName,
                                        withQueryValueAt: queryParameterKey ?? fieldName,
                                        as: queryValueType,
                                        from: self)
    }
}

/// Internal configuration for filter parsing
internal struct FilterConfig {
    public var method: QueryParameterFilter.Method
    public var value: String
}

/// Collection of all query parameter methods and their aliases
internal let AllQueryParameterMethodsAndAliases =
QueryParameterFilter.Method.allCases.map { $0.rawValue } +
QueryParameterFilter.Method.Aliases.allCases.map { $0.rawValue }

internal extension String {
    /// Converts a string to a filter configuration
    /// - Throws: QueryParameterFilterError if the configuration is invalid
    /// - Returns: A FilterConfig instance
    func toFilterConfig() throws -> FilterConfig {
        let values = split(substring: ":")
        guard let method = values?.left, let value = values?.right,
              let qfm = QueryParameterFilter.Method(rawValue: method) ?? QueryParameterFilter.Method.Aliases(rawValue: method)?.toMethod() else {
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
        
        return FilterConfig(method: qfm, value: value)
    }
    
    /// Extracts captured groups from a string using a regex pattern
    /// - Parameter pattern: The regex pattern to match
    /// - Returns: Array of captured groups as optional strings
    func capturedGroups(withRegex pattern: String) -> [String?] {
        var results = [String?]()
        
        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            return results
        }
        
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: count))
        
        guard let match = matches.first else { return results }
        
        let lastRangeIndex = match.numberOfRanges - 1
        guard lastRangeIndex >= 1 else { return results }
        
        for i in 1 ... lastRangeIndex {
            let capturedGroupIndex = match.range(at: i)
            
            let matchedString: String? = capturedGroupIndex.location == NSNotFound ? nil : NSString(string: self).substring(with: capturedGroupIndex)
            
            results.append(matchedString)
        }
        
        return results
    }
}
