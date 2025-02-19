//
//  Parameters+ModelResolution.swift
//
//
//  Created by Brian Strobach on 2/18/25.
//

import Foundation

public extension Parameters {
    func next<P>(on database: Database) async throws -> P?
    where P: Model & Parameter, P.ResolvedParameter == P.IDValue {
        return try await next(P.self, on: database)
    }

    func assertNext<P>(on database: Database) async throws -> P
    where P: Model & Parameter, P.ResolvedParameter == P.IDValue {
        return try await assertNext(P.self, on: database)
    }

    func nextIfExists<P>(_ parameterType: P.Type, on database: Database) async throws -> P? where P: Model & Parameter, P.ResolvedParameter == P.IDValue {
        let id: P.IDValue = try self.require(parameterType.parameter, as: P.ResolvedParameter.self)
        return try await P.find(id, on: database)
    }

    func assertNext<P>(_ parameterType: P.Type, on database: Database) async throws -> P where P: Model & Parameter, P.ResolvedParameter == P.IDValue {
        let value: P? = try await self.next(parameterType, on: database)
        return try value.assertExists()
    }
}
