//
//  RoutesBuilder+Async.swift
//
//
//  Created by Brian Strobach on 4/15/22.
//

import Vapor
import RoutingKitExtensions

public extension RoutesBuilder {

    @discardableResult
    func get<R: AsyncResponseEncodable>(_ path: PathComponentRepresentable...,
                                        use closure: @escaping (Request) async throws -> R) -> Route {
        on(.GET, path.pathComponents, use: closure)
        
    }
    
    @discardableResult
    func get<R: AsyncResponseEncodable>(_ path: [PathComponentRepresentable],
                                        use closure: @escaping (Request) async throws -> R) -> Route {
        on(.GET, path.pathComponents, use: closure)
        
    }

    @discardableResult
    func put<C: Codable, R: AsyncResponseEncodable>(_ body: C.Type = C.self,
                                                 at path: PathComponentRepresentable...,
                                                 use closure: @escaping (Request, C) async throws -> R) -> Route {
        on(.PUT, body, at: path, use: closure)
    }

    @discardableResult
    func put<C: Codable, R: AsyncResponseEncodable>(_ body: C.Type = C.self,
                                                 at path: [PathComponentRepresentable],
                                                 use closure: @escaping (Request, C) async throws -> R) -> Route {
        on(.PUT, body, at: path, use: closure)
    }
    

    @discardableResult
    func post<C: Codable, R: AsyncResponseEncodable>(_ body: C.Type = C.self,
                                                     at path: PathComponentRepresentable...,
                                                     use closure: @escaping (Request, C) async throws -> R) -> Route {
        on(.POST, body, at: path, use: closure)
    }

    @discardableResult
    func post<C: Codable, R: AsyncResponseEncodable>(_ body: C.Type = C.self,
                                                  at path: [PathComponentRepresentable],
                                                  use closure: @escaping (Request, C) async throws -> R) -> Route {
        on(.POST, body, at: path, use: closure)

    }

    @discardableResult
    func patch<C: Codable, R: AsyncResponseEncodable>(_ body: C.Type = C.self,
                                                   at path: PathComponentRepresentable...,
                                                   use closure: @escaping (Request, C) async throws -> R) -> Route {
        on(.PATCH, body, at: path, use: closure)
    }

    @discardableResult
    func patch<C: Codable, R: AsyncResponseEncodable>(_ body: C.Type = C.self,
                                                   at path: [PathComponentRepresentable],
                                                   use closure: @escaping (Request, C) async throws -> R) -> Route {
        on(.PATCH, body, at: path, use: closure)
    }

    @discardableResult
    func delete<C: Codable, R: AsyncResponseEncodable>(_ body: C.Type = C.self,
                                                    at path: PathComponentRepresentable...,
                                                    use closure: @escaping (Request, C) async throws -> R) -> Route {
        on(.DELETE, body, at: path, use: closure)
    }

    @discardableResult
    func delete<C: Codable, R: AsyncResponseEncodable>(_ body: C.Type = C.self,
                                                    at path: [PathComponentRepresentable],
                                                    use closure: @escaping (Request, C) async throws -> R) -> Route {
        on(.DELETE, body, at: path, use: closure)
    }

    @discardableResult
    func on<C: Codable, R: AsyncResponseEncodable>(_ method: HTTPMethod,
                                                _ body: C.Type = C.self,
                                                at path: PathComponentRepresentable...,
                                                use closure: @escaping (Request, C) async throws -> R) -> Route {
        on(method, body, at: path, use: closure)

    }

    @discardableResult
    func on<C: Codable, R: AsyncResponseEncodable>(_ method: HTTPMethod,
                                                _ body: C.Type = C.self,
                                                at path: [PathComponentRepresentable],
                                                use closure: @escaping (Request, C) async throws -> R) -> Route {
        on(method, path.pathComponents) { (request: Request) async throws -> R in
            let decodedBody = try request.content.decode(body)
            return try await closure(request, decodedBody)
        }

    }
}

//TODO: Figure out if this is redundant or why this is commented out
public extension RoutesBuilder {

//    @discardableResult
//    func get<C: Codable, R: ResponseEncodable>(_ body: C.Type = C.self,
//                                                 at path: PathComponentRepresentable...,
//                                                 use closure: @escaping (Request, C) async throws -> R) -> Route {
//        on(.GET, body, at: path, use: closure)
//
//    }
//
//    @discardableResult
//    func get<C: Codable, R: ResponseEncodable>(_ body: C.Type = C.self,
//                                                 at path: [PathComponentRepresentable],
//                                                 use closure: @escaping (Request, C) async throws -> R) -> Route {
//        on(.GET, body, at: path, use: closure)
//
//    }
//
//    @discardableResult
//    func put<C: Codable, R: ResponseEncodable>(_ body: C.Type = C.self,
//                                                 at path: PathComponentRepresentable...,
//                                                 use closure: @escaping (Request, C) async throws -> R) -> Route {
//        on(.PUT, body, at: path, use: closure)
//    }
//
//    @discardableResult
//    func put<C: Codable, R: ResponseEncodable>(_ body: C.Type = C.self,
//                                                 at path: [PathComponentRepresentable],
//                                                 use closure: @escaping (Request, C) async throws -> R) -> Route {
//        on(.PUT, body, at: path, use: closure)
//    }
//
//    @discardableResult
//    func post<C: Codable, R: ResponseEncodable>(_ body: C.Type = C.self,
//                                                  at path: PathComponentRepresentable...,
//                                                  use closure: @escaping (Request, C) async throws -> R) -> Route {
//        on(.POST, body, at: path, use: closure)
//
//    }
//
//    @discardableResult
//    func post<C: Codable, R: ResponseEncodable>(_ body: C.Type = C.self,
//                                                  at path: [PathComponentRepresentable],
//                                                  use closure: @escaping (Request, C) async throws -> R) -> Route {
//        on(.POST, body, at: path, use: closure)
//
//    }
//
//    @discardableResult
//    func patch<C: Codable, R: ResponseEncodable>(_ body: C.Type = C.self,
//                                                   at path: PathComponentRepresentable...,
//                                                   use closure: @escaping (Request, C) async throws -> R) -> Route {
//        on(.PATCH, body, at: path, use: closure)
//    }
//
//    @discardableResult
//    func patch<C: Codable, R: ResponseEncodable>(_ body: C.Type = C.self,
//                                                   at path: [PathComponentRepresentable],
//                                                   use closure: @escaping (Request, C) async throws -> R) -> Route {
//        on(.PATCH, body, at: path, use: closure)
//    }
//
//    @discardableResult
//    func delete<C: Codable, R: ResponseEncodable>(_ body: C.Type = C.self,
//                                                    at path: PathComponentRepresentable...,
//                                                    use closure: @escaping (Request, C) async throws -> R) -> Route {
//        on(.DELETE, body, at: path, use: closure)
//    }
//
//    @discardableResult
//    func delete<C: Codable, R: ResponseEncodable>(_ body: C.Type = C.self,
//                                                    at path: [PathComponentRepresentable],
//                                                    use closure: @escaping (Request, C) async throws -> R) -> Route {
//        on(.DELETE, body, at: path, use: closure)
//    }
//
//    @discardableResult
//    func on<C: Codable, R: ResponseEncodable>(_ method: HTTPMethod,
//                                                _ body: C.Type = C.self,
//                                                at path: PathComponentRepresentable...,
//                                                use closure: @escaping (Request, C) async throws -> R) -> Route {
//        on(method, body, at: path, use: closure)
//
//    }
//
//    @discardableResult
//    func on<C: Codable & Parameter, R: ResponseEncodable>(_ method: HTTPMethod,
//                                                _ body: C.Type = C.self,
//                                                at path: [PathComponentRepresentable],
//                                                use closure: @escaping (Request, C) async throws -> R) -> Route {
//        on(method, path) { request -> R in
//            let params = try request.parameters.next(C.self)
//            return try closure(request, params)
//        }
//
//    }
    

}

