//
//  Model+AsyncCRUD.swift
//  
//
//  Created by Brian Strobach on 7/27/24.
//

import Fluent

public extension Model {
    @discardableResult
    func update(in database: Database) async throws -> Self {
        try await self.update(on: database).get()
        return self
    }
    
    @discardableResult
    func create(in database: Database) async throws -> Self {
        try await self.create(on: database).get()
        return self
    }
    
    @discardableResult
    func save(in database: Database) async throws -> Self {
        try await self.save(on: database).get()
        return self
    }
    
    @discardableResult
    func delete(from database: Database) async throws -> Self {
        try await self.delete(on: database).get()
        return self
    }
    
    @discardableResult
    func restore(in database: Database) async throws -> Self {
        try await self.restore(on: database).get()
        return self
    }
}
