//
//  Joinable.swift
//
//
//  Created by Brian Strobach on 10/26/21.
//

import Fluent
import CollectionConcurrencyKit

public protocol Joinable {
    associatedtype Joined: Content
    func joined(on req: Request) async throws -> Joined
}

public extension Collection where Element: Joinable {
    func joined(on req: Request) async throws -> [Element.Joined] {
        try await concurrentMap { element in
            try await element.joined(on: req)
        }
    }
}

public extension Sequence where Element: Joinable {
    func joined(on request: Request) async throws -> [Element.Joined] {
        try await concurrentMap { element in
            try await element.joined(on: request)
        }
    }
}
