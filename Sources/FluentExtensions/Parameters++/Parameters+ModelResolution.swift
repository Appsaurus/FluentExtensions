//
//  Parameters+ModelResolution.swift
//
//
//  Created by Brian Strobach on 2/18/25.
//

import Foundation

/// Extension providing convenient model resolution methods from route parameters
public extension Parameters {
    /// Attempts to find a model instance using the parameter value
    /// - Parameters:
    ///   - database: The database connection to query
    /// - Returns: The resolved model instance if found, nil otherwise
    /// - Throws: Any errors encountered during parameter resolution or database query
    func next<P>(on database: Database) async throws -> P?
    where P: Model & Parameter, P.ResolvedParameter == P.IDValue {
        return try await next(P.self, on: database)
    }

    /// Resolves and returns a model instance, throwing if not found
    /// - Parameters:
    ///   - database: The database connection to query
    /// - Returns: The resolved model instance
    /// - Throws: Any errors encountered during parameter resolution or database query
    func assertNext<P>(on database: Database) async throws -> P
    where P: Model & Parameter, P.ResolvedParameter == P.IDValue {
        return try await assertNext(P.self, on: database)
    }

    /// Attempts to find a model instance by ID if it exists
    /// - Parameters:
    ///   - parameterType: The model type to resolve
    ///   - database: The database connection to query
    /// - Returns: The resolved model instance if found, nil otherwise
    /// - Throws: Any errors encountered during parameter resolution or database query
    func nextIfExists<P>(_ parameterType: P.Type, on database: Database) async throws -> P? where P: Model & Parameter, P.ResolvedParameter == P.IDValue {
        let id: P.IDValue = try self.require(parameterType.parameter, as: P.ResolvedParameter.self)
        return try await P.find(id, on: database)
    }

    /// Resolves and returns a model instance of the specified type, throwing if not found
    /// - Parameters:
    ///   - parameterType: The model type to resolve
    ///   - database: The database connection to query
    /// - Returns: The resolved model instance
    /// - Throws: Any errors encountered during parameter resolution or database query
    func assertNext<P>(_ parameterType: P.Type, on database: Database) async throws -> P where P: Model & Parameter, P.ResolvedParameter == P.IDValue {
        let value: P? = try await self.next(parameterType, on: database)
        return try value.assertExists()
    }
}
