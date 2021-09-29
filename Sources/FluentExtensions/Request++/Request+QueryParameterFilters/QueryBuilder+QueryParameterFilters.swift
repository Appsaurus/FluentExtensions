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

    func filterByQueryParameters(request: Request) throws -> QueryBuilder<Model> {
        var query = self
        for property in try properties(Model.self) {
            query = try filterByQueryParameter(for: property, on: request)
        }
        return query
    }

    func filterByQueryParameter(for property: PropertyInfo, on request: Request) throws -> QueryBuilder<Model> {
        var query = self
        let parameterName: String = property.name
        if let filterable = property.type as? AnyProperty.Type,
           let queryFilter = try? request.stringKeyPathFilter(for: parameterName, using: parameterName.droppingUnderscorePrefix) {
            query = try filter(queryFilter, as: filterable.anyValueType)
        }
        return query
    }
}

//public extension QueryBuilder where Model: Content {
//
//    func paginate(
//        on req: Request,
//        sorts: [DatabaseQuery.Sort]) throws -> Future<Paginated<Model>> {
//        return try self.page(for: req, sorts: sorts, {$0.all()}).map { Paginated<Model>(from: $0) }
//    }
//

//
//    func paginate<R, T>(
//        on req: Request,
//        response type: T.Type = T.self,
//        sorts: [DatabaseQuery.Sort],
//        _ transformation: @escaping (QueryBuilder<Model>) throws -> Future<[R]>
//    ) throws -> Future<T> where T: PaginatedResponse, T.DataType == R {
//
//        return try self.page(for: req, sorts: sorts, transformation).map(to: type.self) { type.init(from: $0) }
//    }
//}


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
                                      at queryParameter: String? = nil,
                                      on req: Request) throws -> QueryBuilder<Model> {
        guard let queryFilter = try req.stringKeyPathFilter(for: keyPath, using: queryParameter) else {
            return self
        }
        return try filter(queryFilter)
    }


    @discardableResult
    func filter(_ keyPath: String,
                at queryParameter: String? = nil,
                on req: Request) throws -> QueryBuilder<Model> {
        guard let queryFilter = try req.stringKeyPathFilter(for: keyPath, using: queryParameter) else {
            return self
        }
        return try filter(queryFilter)
    }


    @discardableResult
    func filter(_ stringKeyPathFilter: StringKeyPathFilter, as type: Any.Type? = nil) throws -> QueryBuilder<Model> {
        return try filter(stringKeyPathFilter.filter, as: type)
    }

    @discardableResult
    func filter(_ queryParameterFilter: QueryParameterFilter, as type: Any.Type? = nil) throws -> QueryBuilder<Model>{
        switch type {
            case is Bool.Type, is Int.Type:
                return try filterAsBool(queryParameterFilter)
            default: break
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


    //    @discardableResult
    //    func filterAs(_ type: Any.Type, _ stringkeyPathFilter: StringKeyPathFilter) throws -> QueryBuilder<Model> {
    //
    //    }

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

