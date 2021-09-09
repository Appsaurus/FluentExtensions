//
//  RoutesBuilder+ModelParameter.swift
//  
//
//  Created by Brian Strobach on 9/8/21.
//


import VaporExtensions

public extension RoutesBuilder {

    @discardableResult
    func get<P: Parameter, R: ResponseEncodable>(_ path: PathComponentRepresentable...,
                                                 params: P.Type = P.self,
                                                 use closure: @escaping (Request, P) throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.GET, path, params: params, use: closure)

    }

    @discardableResult
    func put<P: Parameter, R: ResponseEncodable>(_ path: PathComponentRepresentable...,
                                                 params: P.Type = P.self,
                                                 use closure: @escaping (Request, P) throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.PUT, path, params: params, use: closure)
    }

    @discardableResult
    func post<P: Parameter, R: ResponseEncodable>(_ path: PathComponentRepresentable...,
                                                  params: P.Type = P.self,
                                                  use closure: @escaping (Request, P) throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.POST, path, params: params, use: closure)

    }

    @discardableResult
    func patch<P: Parameter, R: ResponseEncodable>(_ path: PathComponentRepresentable...,
                                                   params: P.Type = P.self,
                                                   use closure: @escaping (Request, P) throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.PATCH, path, params: params, use: closure)
    }

    @discardableResult
    func delete<P: Parameter, R: ResponseEncodable>(_ path: PathComponentRepresentable...,
                                                    params: P.Type = P.self,
                                                    use closure: @escaping (Request, P) throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.DELETE, path, params: params, use: closure)
    }

    @discardableResult
    func on<P: Parameter, R: ResponseEncodable>(_ method: HTTPMethod,
                                                _ path: PathComponentRepresentable...,
                                                params: P.Type = P.self,
                                                use closure: @escaping (Request, P) throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(method, path, params: params, use: closure)

    }

    @discardableResult
    func on<P: Parameter, R: ResponseEncodable>(_ method: HTTPMethod,
                                                _ path: [PathComponentRepresentable],
                                                params: P.Type = P.self,
                                                use closure: @escaping (Request, P) throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(method, path) { request in
            return request.parameters.next(P.self, on: request.db).flatMapThrowing({ (params) -> R in
                return try closure(request, params)
            })
        }
    }
}


extension Parameter where Self: Model {
    public typealias ResolvedParameter = Self.IDValue
    public static var parameter: String {
        return "id"
    }
}

public extension Parameters {
    func next<P>(on database: Database) -> EventLoopFuture<P>
    where P: Model & Parameter, P.ResolvedParameter == P.IDValue {
        return next(P.self, on: database)
    }

    func next<P>(_ parameterType: P.Type, on database: Database) -> EventLoopFuture<P> where P: Model & Parameter, P.ResolvedParameter == P.IDValue {
        do {
            let id: P.IDValue = try self.require(parameterType.parameter, as: P.ResolvedParameter.self)
            return P.find(id, on: database).assertExists()
        }
        catch {
            return database.fail(with: error)
        }

    }
}
