//
//  RoutesBuilder+ModelParameter.swift
//
//  Created by Brian Strobach on 9/8/21.
//

import VaporExtensions

/// Extension to `RoutesBuilder` that provides convenient route handling methods for Model parameters
public extension RoutesBuilder {
    
    /// Creates a GET route that expects a Model parameter
    /// - Parameters:
    ///   - path: Variadic list of path components
    ///   - params: The Model parameter type
    ///   - closure: The route handler
    /// - Returns: The created `Route`
    @discardableResult
    func get<P: Parameter, R: AsyncResponseEncodable>(_ path: PathComponentRepresentable...,
                                                      params: P.Type = P.self,
                                                      use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.GET, path, params: params, use: closure)
    }
    
    /// Creates a GET route that expects a Model parameter
    /// - Parameters:
    ///   - path: Array of path components
    ///   - params: The Model parameter type
    ///   - closure: The route handler
    /// - Returns: The created `Route`
    @discardableResult
    func get<P: Parameter, R: AsyncResponseEncodable>(_ path: [PathComponentRepresentable],
                                                      params: P.Type = P.self,
                                                      use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.GET, path, params: params, use: closure)
    }
    
    /// Creates a PUT route that expects a Model parameter
    /// - Parameters:
    ///   - path: Variadic list of path components
    ///   - params: The Model parameter type
    ///   - closure: The route handler
    /// - Returns: The created `Route`
    @discardableResult
    func put<P: Parameter, R: AsyncResponseEncodable>(_ path: PathComponentRepresentable...,
                                                      params: P.Type = P.self,
                                                      use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.PUT, path, params: params, use: closure)
    }
    
    /// Creates a PUT route that expects a Model parameter
    /// - Parameters:
    ///   - path: Array of path components
    ///   - params: The Model parameter type
    ///   - closure: The route handler
    /// - Returns: The created `Route`
    @discardableResult
    func put<P: Parameter, R: AsyncResponseEncodable>(_ path: [PathComponentRepresentable],
                                                      params: P.Type = P.self,
                                                      use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.PUT, path, params: params, use: closure)
    }
    
    /// Creates a POST route that expects a Model parameter
    @discardableResult
    func post<P: Parameter, R: AsyncResponseEncodable>(_ path: PathComponentRepresentable...,
                                                       params: P.Type = P.self,
                                                       use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.POST, path, params: params, use: closure)
    }
    
    /// Creates a POST route that expects a Model parameter
    @discardableResult
    func post<P: Parameter, R: AsyncResponseEncodable>(_ path: [PathComponentRepresentable],
                                                       params: P.Type = P.self,
                                                       use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.POST, path, params: params, use: closure)
    }
    
    /// Creates a PATCH route that expects a Model parameter
    @discardableResult
    func patch<P: Parameter, R: AsyncResponseEncodable>(_ path: PathComponentRepresentable...,
                                                        params: P.Type = P.self,
                                                        use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.PATCH, path, params: params, use: closure)
    }
    
    /// Creates a PATCH route that expects a Model parameter
    @discardableResult
    func patch<P: Parameter, R: AsyncResponseEncodable>(_ path: [PathComponentRepresentable],
                                                        params: P.Type = P.self,
                                                        use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.PATCH, path, params: params, use: closure)
    }
    
    /// Creates a DELETE route that expects a Model parameter
    @discardableResult
    func delete<P: Parameter, R: AsyncResponseEncodable>(_ path: PathComponentRepresentable...,
                                                         params: P.Type = P.self,
                                                         use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.DELETE, path, params: params, use: closure)
    }
    
    /// Creates a DELETE route that expects a Model parameter
    @discardableResult
    func delete<P: Parameter, R: AsyncResponseEncodable>(_ path: [PathComponentRepresentable],
                                                         params: P.Type = P.self,
                                                         use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.DELETE, path, params: params, use: closure)
    }
    
    /// Creates a route with a specified HTTP method that expects a Model parameter
    @discardableResult
    func on<P: Parameter, R: AsyncResponseEncodable>(_ method: HTTPMethod,
                                                     _ path: PathComponentRepresentable...,
                                                     params: P.Type = P.self,
                                                     use closure: @escaping (Request, P) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(method, path, params: params, use: closure)
    }
    
    /// Base implementation for creating a route with a Model parameter
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

/// Extension to Parameter for Model types
extension Parameter where Self: Model {
    /// The type used to resolve the parameter
    public typealias ResolvedParameter = Self.IDValue
    
    /// The parameter key used in the URL path
    public static var parameter: String {
        return "id"
    }
}

/// Extension to Parameters for handling Model parameters
public extension Parameters {
    /// Fetches the next parameter as a Model instance
    /// - Parameters:
    ///   - parameterType: The Model type to fetch
    ///   - database: The database connection
    /// - Returns: The fetched Model instance
    /// - Throws: NotFound error if the Model cannot be found
    func next<P>(_ parameterType: P.Type = P.self, on database: Database) async throws -> P
    where P: Model & Parameter, P.ResolvedParameter == P.IDValue {
        let id: P.IDValue = try self.require(parameterType.parameter, as: P.ResolvedParameter.self)
        guard let model = try await P.find(id, on: database) else {
            throw Abort(.notFound)
        }
        return model
    }
}

/// Extension to RoutesBuilder for handling routes with both body content and Model parameters
public extension RoutesBuilder {
    
    /// Creates a PUT route that expects both a body content and a Model parameter
    @discardableResult
    func put<P: Parameter, B: Codable, R: AsyncResponseEncodable>(_ body: B.Type = B.self,
                                                                  at path: PathComponentRepresentable...,
                                                                  params: P.Type = P.self,
                                                                  use closure: @escaping (Request, P, B) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.PUT, body: body, at: path, params: params, use: closure)
    }
    
    /// Creates a PUT route that expects both a body content and a Model parameter
    @discardableResult
    func put<P: Parameter, B: Codable, R: AsyncResponseEncodable>(_ body: B.Type = B.self,
                                                                  at path: [PathComponentRepresentable],
                                                                  params: P.Type = P.self,
                                                                  use closure: @escaping (Request, P, B) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(.PUT, body: body, at: path, params: params, use: closure)
    }
    
    /// Creates a route with a specified HTTP method that expects both a body content and a Model parameter
    @discardableResult
    func on<P: Parameter, B: Codable, R: AsyncResponseEncodable>(_ method: HTTPMethod,
                                                                 body: B.Type = B.self,
                                                                 _ path: PathComponentRepresentable...,
                                                                 params: P.Type = P.self,
                                                                 use closure: @escaping (Request, P, B) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(method, body: body, at: path, params: params, use: closure)
    }
    
    /// Base implementation for creating a route with both body content and Model parameter
    @discardableResult
    func on<P: Parameter, B: Codable, R: AsyncResponseEncodable>(_ method: HTTPMethod,
                                                                 body: B.Type = B.self,
                                                                 at path: [PathComponentRepresentable],
                                                                 params: P.Type = P.self,
                                                                 use closure: @escaping (Request, P, B) async throws -> R) -> Route where P: Model, P.ResolvedParameter == P.IDValue {
        on(method, path) { request async throws -> R in
            let params = try await request.parameters.next(P.self, on: request.db)
            let decodedBody = try request.content.decode(body)
            return try await closure(request, params, decodedBody)
        }
    }
}
