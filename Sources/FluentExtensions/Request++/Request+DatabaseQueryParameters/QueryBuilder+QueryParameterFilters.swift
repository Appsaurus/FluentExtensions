//
//  QueryBuilder+QueryParameterFilters.swift
//  
//
//  Created by Brian Strobach on 9/7/21.
//
import Fluent
import RuntimeExtensions
import CodableExtensions
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



public extension QueryBuilder {
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

    
    @discardableResult
    func filter(_ queryParameterFilter: QueryParameterFilter) throws -> QueryBuilder<Model>{
        
        let queryField = queryParameterFilter.queryField()
        //        let encodableValue: AnyCodable = queryParameterFilter.value.to(type: type)
        switch (queryParameterFilter.method, queryParameterFilter.value) {
        case let (.equal, .single(value)): // Equal
            return self.filter(queryField, .equal, try queryParameterFilter.encodableValue(for: value))
        case let (.notEqual, .single(value)): // Not Equal
            return self.filter(queryField, .notEqual, try queryParameterFilter.encodableValue(for: value))
        case let (.greaterThan, .single(value)): // Greater Than
            return self.filter(queryField, .greaterThan, try queryParameterFilter.encodableValue(for: value))
        case let (.greaterThanOrEqual, .single(value)): // Greater Than Or Equal
            return self.filter(queryField, .greaterThanOrEqual, try queryParameterFilter.encodableValue(for: value))
        case let (.lessThan, .single(value)): // Less Than
            return self.filter(queryField, .lessThan, try queryParameterFilter.encodableValue(for: value))
        case let (.lessThanOrEqual, .single(value)): // Less Than Or Equal
            return self.filter(queryField, .lessThanOrEqual, try queryParameterFilter.encodableValue(for: value))
        case let (.in, .multiple(value)): // In
            return self.filter(queryField, .inSubSet, try queryParameterFilter.encodableValue(for: value))
        case let (.notIn, .multiple(value)): // Not In
            return self.filter(queryField, .notInSubSet, try queryParameterFilter.encodableValue(for: value))
        default:
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
    }
    
    
    
    @discardableResult
    fileprivate func filter(_ field: DatabaseQuery.Field,
                            _ method: DatabaseQuery.Filter.Method,
                            _ value: Encodable) -> QueryBuilder<Model>{
        self.filter(.value(field, method, DatabaseQuery.Value.bind(value)))
        return self
    }
    
    @discardableResult
    fileprivate func filter(_ field: DatabaseQuery.Field,
                            _ method: DatabaseQuery.Filter.Method,
                            _ value: [Encodable]) -> QueryBuilder<Model>{
        let values = value.map({DatabaseQuery.Value.bind($0)})
        self.filter(.value(field, method, DatabaseQuery.Value.array(values)))
        return self
    }
}

public enum QueryParameterFilterError: Error, LocalizedError, CustomStringConvertible {
    case invalidFilterConfiguration
    
    
    public var description: String {
        switch self {
        case .invalidFilterConfiguration:
            return "Invalid filter config."
        }
    }
    
    public var errorDescription: String? {
        return self.description
    }
}


fileprivate extension String {
    /// Converts the string to a `Bool` or returns `nil`.
    var bool: Bool? {
        switch self {
        case "true", "yes", "1", "y": return true
        case "false", "no", "0", "n": return false
        default: return nil
        }
    }
}

