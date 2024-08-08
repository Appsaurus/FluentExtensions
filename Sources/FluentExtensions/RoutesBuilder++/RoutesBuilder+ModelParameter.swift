//
//  RoutesBuilder+ModelParameter.swift
//
//
//  Created by Brian Strobach on 9/8/21.
//

import VaporExtensions

public extension RoutesBuilder {

    @discardableResult
    func get<P: Parameter, R: AsyncResponseEncodable>(_ path: PathComponentRepresentable...,
                                                 params: P.Type = P.self,
                                                 use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.GET, path, params: params, use: closure)
    }

    @discardableResult
    func get<P: Parameter, R: AsyncResponseEncodable>(_ path: [PathComponentRepresentable],
                                                 params: P.Type = P.self,
                                                 use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.GET, path, params: params, use: closure)
    }

    @discardableResult
    func put<P: Parameter, R: AsyncResponseEncodable>(_ path: PathComponentRepresentable...,
                                                 params: P.Type = P.self,
                                                 use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.PUT, path, params: params, use: closure)
    }

    @discardableResult
    func put<P: Parameter, R: AsyncResponseEncodable>(_ path: [PathComponentRepresentable],
                                                 params: P.Type = P.self,
                                                 use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.PUT, path, params: params, use: closure)
    }

    @discardableResult
    func post<P: Parameter, R: AsyncResponseEncodable>(_ path: PathComponentRepresentable...,
                                                  params: P.Type = P.self,
                                                  use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.POST, path, params: params, use: closure)
    }

    @discardableResult
    func post<P: Parameter, R: AsyncResponseEncodable>(_ path: [PathComponentRepresentable],
                                                  params: P.Type = P.self,
                                                  use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.POST, path, params: params, use: closure)
    }

    @discardableResult
    func patch<P: Parameter, R: AsyncResponseEncodable>(_ path: PathComponentRepresentable...,
                                                   params: P.Type = P.self,
                                                   use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.PATCH, path, params: params, use: closure)
    }

    @discardableResult
    func patch<P: Parameter, R: AsyncResponseEncodable>(_ path: [PathComponentRepresentable],
                                                   params: P.Type = P.self,
                                                   use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.PATCH, path, params: params, use: closure)
    }

    @discardableResult
    func delete<P: Parameter, R: AsyncResponseEncodable>(_ path: PathComponentRepresentable...,
                                                    params: P.Type = P.self,
                                                    use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.DELETE, path, params: params, use: closure)
    }

    @discardableResult
    func delete<P: Parameter, R: AsyncResponseEncodable>(_ path: [PathComponentRepresentable],
                                                    params: P.Type = P.self,
                                                    use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.DELETE, path, params: params, use: closure)
    }

    @discardableResult
    func on<P: Parameter, R: AsyncResponseEncodable>(_ method: HTTPMethod,
                                                _ path: PathComponentRepresentable...,
                                                params: P.Type = P.self,
                                                use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(method, path, params: params, use: closure)
    }

    @discardableResult
    func on<P: Parameter, R: AsyncResponseEncodable>(_ method: HTTPMethod,
                                                _ path: [PathComponentRepresentable],
                                                params: P.Type = P.self,
                                                use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(method, path) { request async throws -> R in
            let params = try await request.parameters.next(P.self, on: request.db)
            return try await closure(request, params)
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
    func next<P>(_ parameterType: P.Type = P.self, on database: Database) async throws -> P
    where P: Model & Parameter, P.ResolvedParameter == P.IDValue {
        let id: P.IDValue = try self.require(parameterType.parameter, as: P.ResolvedParameter.self)
        guard let model = try await P.find(id, on: database) else {
            throw Abort(.notFound)
        }
        return model
    }
}
