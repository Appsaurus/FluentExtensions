//
//  FlatQueryParametersFilter.swift
//
//
//  Created by Brian Strobach on 2/13/25.
//

import Vapor
import Foundation
import Fluent
import Codability


public extension QueryBuilder {
    
    @discardableResult
    func filterByQueryParameters(request: Request) throws -> QueryBuilder<Model> {
        var query = self
        for property in try Model.reflectedSchemaProperties() {
            query = try filter(property, on: request)
        }
        return query
    }
    
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


extension QueryBuilder {
    
    @discardableResult
    func filter<V: QueryableProperty>(keyPath: KeyPath<Model,V>,
                                      queryParameterFilter: QueryParameterFilter) throws -> QueryBuilder<Model> {
        queryParameterFilter.name = keyPath.propertyName
        return try filter(queryParameterFilter)
    }
    
    @discardableResult
    func filter<V: QueryableProperty>(keyPath: KeyPath<Model,V>,
                                      withQueryValueAt queryParameterKey: String? = nil,
                                      on req: Request) throws -> QueryBuilder<Model> {
        guard let queryFilter = try req.query.parseFilter(for: keyPath, withQueryValueAt: queryParameterKey) else {
            return self
        }
        return try filter(queryFilter)
    }
    
    
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
extension QueryParameterFilter {
    public convenience init(schema: Schema.Type,
                            fieldName: String,
                            withQueryValueAt queryParameterKey: String,
                            as queryValueType: Any.Type? = nil,
                            from queryContainer: URLQueryContainer) throws {
        
        let decoder = URLEncodedFormDecoder()
        
        guard let config = queryContainer[String.self, at: queryParameterKey] else {
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
        
        let filterConfig = config.toFilterConfig
        
        let method = filterConfig.method
        let value = filterConfig.value
        
        let multiple = [.in, .notIn].contains(method)
        var filterValue: QueryParameterFilter.Value<String, [String]>
        
        if multiple {
            let str = value.components(separatedBy: ",").map { "\(queryParameterKey)[]=\($0)" }.joined(separator: "&")
            filterValue = try .multiple(decoder.decode(SingleValueDecoder.self, from: str).get(at: [queryParameterKey.codingKey]))
        } else {
            let str = "\(queryParameterKey)=\(value)"
            filterValue = try .single(decoder.decode(SingleValueDecoder.self, from: str).get(at: [queryParameterKey.codingKey]))
        }
        self.init(schema: schema,
                  name: fieldName,
                  method: method,
                  value: filterValue,
                  queryValueType: queryValueType)
    }
}
public extension URLQueryContainer {
    
    func parseFilter<V: QueryableProperty, M: Model>(for keyPath: KeyPath<M,V>,
                                                     withQueryValueAt queryParameterKey: String? = nil,
                                                     as queryValueType: Any.Type? = nil) throws -> QueryParameterFilter? {
        try parseFilter(for: M.self,
                           at: keyPath.codingKeys,
                           withQueryValueAt: queryParameterKey,
                           as: queryValueType ?? V.self.Value)
    }

    func parseFilter(for schema: Schema.Type,
                     at keyPath: CodingKeyRepresentable...,
                     withQueryValueAt queryParameterKey: String? = nil,
                     as queryValueType: Any.Type? = nil) throws -> QueryParameterFilter? {
        try parseFilter(for: schema, at: keyPath, withQueryValueAt: queryParameterKey, as: queryValueType)

    }
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


internal struct FilterConfig {
    public var method: QueryParameterFilter.Method
    public var value: String
}

internal let FILTER_CONFIG_REGEX = "(\(QueryParameterFilter.Method.allCases.map { $0.rawValue }.joined(separator: "|")))?:?(.*)"

internal extension String {
    var toFilterConfig: FilterConfig {
        let result = capturedGroups(withRegex: FILTER_CONFIG_REGEX)

        var method = QueryParameterFilter.Method.equal

        if let rawValue = result[0], let qfm = QueryParameterFilter.Method(rawValue: rawValue) {
            method = qfm
        }

        return FilterConfig(method: method, value: result[1] ?? "")
    }

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
