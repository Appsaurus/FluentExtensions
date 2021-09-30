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
        for property in try properties(Model.self) {
            query = try filter(property, on: request)
        }
        return query
    }

    @discardableResult
    func filter(_ property: PropertyInfo,
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
        if let queryFilter = try? request.stringKeyPathFilter(for: keyPath, withQueryValueAt: queryParameterKey, as: queryValueType) {
            query = try filter(queryFilter)
        }
        return query
    }
}

public extension QueryBuilder {

    func sorted(byQueryParamsAt key: String = "sort", on req: Request) throws -> Self {
        for sort in try sorts(byQueryParamsAt: key, on: req) {
            _ = self.sort(sort)
        }
        return self
    }

    func sorts(byQueryParamsAt key: String = "sort", on req: Request) throws -> [DatabaseQuery.Sort] {
        var sorts: [DatabaseQuery.Sort] = []
        if let sort = req.query[String.self, at: key] {
            sorts = try Model.sorts(fromQueryParam: sort)
        }
        return sorts
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
        guard let queryFilter = try req.stringKeyPathFilter(for: keyPath, withQueryValueAt: queryParameterKey) else {
            return self
        }
        return try filter(queryFilter)
    }


    @discardableResult
    func filter(_ keyPath: String,
                withQueryValueAt queryParameterKey: String? = nil,
                on req: Request) throws -> QueryBuilder<Model> {
        guard let queryFilter = try req.stringKeyPathFilter(for: keyPath, withQueryValueAt: queryParameterKey) else {
            return self
        }
        return try filter(queryFilter)
    }


    @discardableResult
    func filter(_ stringKeyPathFilter: StringKeyPathFilter) throws -> QueryBuilder<Model> {
        return try filter(stringKeyPathFilter.filter)
    }

    @discardableResult
    func filter(_ queryParameterFilter: QueryParameterFilter) throws -> QueryBuilder<Model>{
        if let valueType = queryParameterFilter.queryValueType {
            switch valueType {
                case is Bool.Type, is Int.Type:
                    return try filterAsBool(queryParameterFilter)
                default: break
            }
        }

        let queryField = queryParameterFilter.queryField(for: Model.schema)
        //        let encodableValue: AnyCodable = queryParameterFilter.value.to(type: type)
        switch (queryParameterFilter.method, queryParameterFilter.value) {
        case let (.equal, .single(value)): // Equal
            return self.filter(queryField, .equal, value)
        case let (.notEqual, .single(value)): // Not Equal
            return self.filter(queryField, .notEqual, value)
        case let (.greaterThan, .single(value)): // Greater Than
            return self.filter(queryField, .greaterThan, value)
        case let (.greaterThanOrEqual, .single(value)): // Greater Than Or Equal
            return self.filter(queryField, .greaterThanOrEqual, value)
        case let (.lessThan, .single(value)): // Less Than
            return self.filter(queryField, .lessThan, value)
        case let (.lessThanOrEqual, .single(value)): // Less Than Or Equal
            return self.filter(queryField, .lessThanOrEqual, value)
        case let (.in, .multiple(value)): // In
            return self.filter(queryField, .inSubSet, value)
        case let (.notIn, .multiple(value)): // Not In
            return self.filter(queryField, .notInSubSet, value)
        default:
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
    }

    @discardableResult
    func filterAsBool(_ queryParameterFilter: QueryParameterFilter) throws -> QueryBuilder<Model> {
        let queryField = queryParameterFilter.queryField(for: Model.schema)
        //        let encodableValue: AnyCodable = queryParameterFilter.value.to(type: type(of: property).anyValueType)
        switch (queryParameterFilter.method, queryParameterFilter.value) {
        case let (.equal, .single(value)): // Equal
            return self.filter(queryField, .equal, value.bool)
        case let (.notEqual, .single(value)): // Not Equal
            return self.filter(queryField, .notEqual, value.bool)
        case let (.greaterThan, .single(value)): // Greater Than
            return self.filter(queryField, .greaterThan, value.bool)
        case let (.greaterThanOrEqual, .single(value)): // Greater Than Or Equal
            return self.filter(queryField, .greaterThanOrEqual, value.bool)
        case let (.lessThan, .single(value)): // Less Than
            return self.filter(queryField, .lessThan, value.bool)
        case let (.lessThanOrEqual, .single(value)): // Less Than Or Equal
            return self.filter(queryField, .lessThanOrEqual, value.bool)
        case let (.in, .multiple(value)): // In
            return self.filter(queryField, .inSubSet, value.map({ $0.bool}))
        case let (.notIn, .multiple(value)): // Not In
            return self.filter(queryField, .notInSubSet, value.map({ $0.bool}))
        default:
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
    }


    @discardableResult
    fileprivate func filter<E: Encodable>(_ field: DatabaseQuery.Field,
                                          _ method: DatabaseQuery.Filter.Method,
                                          _ value: E) -> QueryBuilder<Model>{
        self.filter(.value(field, method, DatabaseQuery.Value.bind(value)))
        return self
    }

    @discardableResult
    fileprivate func filter<E: Encodable>(_ field: DatabaseQuery.Field,
                                          _ method: DatabaseQuery.Filter.Method,
                                          _ value: [E]) -> QueryBuilder<Model>{
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

