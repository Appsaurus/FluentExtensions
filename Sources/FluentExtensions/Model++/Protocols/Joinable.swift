//
//  Joinable.swift
//  
//
//  Created by Brian Strobach on 10/26/21.
//

import Fluent

public protocol Joinable {
    associatedtype Joined: Content
    func joined(on req: Request) throws -> Future<Joined>
}
public extension Collection where Element: Joinable {
    func joined(on req: Request) throws -> Future<[Element.Joined]> {
        return try map({try $0.joined(on: req)}).flatten(on: req)
    }
}
public extension Future where Value: Joinable {
    func joined(on request: Request) throws -> Future<Value.Joined> {
        tryFlatMap { model in
            try model.joined(on: request)
        }
    }
}

extension Future where Value: Collection, Value.Element: Joinable {
    func joined(on request: Request) throws -> Future<[Value.Element.Joined]> {
        return tryFlatMap { joinable in
            return try joinable.joined(on: request)
        }
    }
}
