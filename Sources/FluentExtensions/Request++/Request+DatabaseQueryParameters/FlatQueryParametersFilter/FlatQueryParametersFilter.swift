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

public extension QueryParameterFilter.Method {
    enum ParameterValueType {
        case single
        case multiple
        case range
    }
    
    var expectedValueType: ParameterValueType {
        if Self.arrayValues.contains(self) {
            return .multiple
        }
        if Self.rangeValues.contains(self) {
            return .range
        }
        return .single
    }
    static var arrayValues: [QueryParameterFilter.Method] {
        return [.arrIncludes,
                .arrIncludesAll,
                .arrIncludesSome,
                .arrNotIncludes
            ]
    }
    
    static var rangeValues: [QueryParameterFilter.Method] {
        return [.between,
                .betweenInclusive,
                .inNumberRange
            ]
    }
}

public struct QueryParameterRangeValue {
    var lowerBound: String
    var upperBound: String
}

fileprivate extension String {
    func toRange() throws -> QueryParameterRangeValue {
        // Remove whitespace and brackets
        let cleaned = self.trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        
        // Split by comma
        let components = cleaned.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        guard components.count == 2 else {
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
        
        return QueryParameterRangeValue(lowerBound: components[0], upperBound: components[1])
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

internal let AllQueryParameterMethodsAndAliases =
QueryParameterFilter.Method.allCases.map { $0.rawValue } +
QueryParameterFilter.Method.Aliases.allCases.map { $0.rawValue }


internal extension String {
    func toFilterConfig() throws -> FilterConfig {
        let values = split(substring: ":")
        guard let method = values?.left, let value = values?.right,
                let qfm = QueryParameterFilter.Method(rawValue: method) ?? QueryParameterFilter.Method.Aliases(rawValue: method)?.toMethod() else {
                throw QueryParameterFilterError.invalidFilterConfiguration
        }
        
        return FilterConfig(method: qfm, value: value)
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
