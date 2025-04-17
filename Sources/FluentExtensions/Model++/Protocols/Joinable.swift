//
//  Joinable.swift
//
//
//  Created by Brian Strobach on 10/26/21.
//

import Fluent
import CollectionConcurrencyKit

/// A protocol that defines an entity that can be joined with related data.
/// 
/// Implement this protocol when you want to provide a standardized way to fetch
/// an entity along with its related data in a single operation.
public protocol Joinable {
    /// The type that represents this entity with its joined related data
    associatedtype Joined: Content
    
    /// Fetches the entity along with its related data
    /// - Parameter req: The request context for database access
    /// - Returns: The entity with its joined related data
    /// - Throws: Any errors that occur during the join operation
    func joined(on req: Request) async throws -> Joined
}

public extension Collection where Element: Joinable {
    /// Concurrently fetches multiple entities along with their related data
    /// - Parameter req: The request context for database access
    /// - Returns: An array of entities with their joined related data
    /// - Throws: Any errors that occur during the join operations
    func joined(on req: Request) async throws -> [Element.Joined] {
        try await concurrentMap { element in
            try await element.joined(on: req)
        }
    }
}

public extension Sequence where Element: Joinable {
    /// Concurrently fetches multiple entities along with their related data
    /// - Parameter request: The request context for database access
    /// - Returns: An array of entities with their joined related data
    /// - Throws: Any errors that occur during the join operations
    func joined(on request: Request) async throws -> [Element.Joined] {
        try await concurrentMap { element in
            try await element.joined(on: request)
        }
    }
}
