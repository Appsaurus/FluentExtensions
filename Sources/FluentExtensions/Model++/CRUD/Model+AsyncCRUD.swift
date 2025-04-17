//
//  Model+AsyncCRUD.swift
//
//
//  Created by Brian Strobach on 7/27/24.
//

import Fluent

public extension Model {
    /// Asynchronously updates the model in the database.
    /// - Parameter database: The database connection to perform the update on
    /// - Returns: The updated model instance
    /// - Throws: Any database errors that occur during the update operation
    @discardableResult
    func update(in database: Database) async throws -> Self {
        try await self.update(on: database).get()
        return self
    }
    
    /// Asynchronously creates the model in the database.
    /// - Parameter database: The database connection to perform the create on
    /// - Returns: The created model instance
    /// - Throws: Any database errors that occur during the create operation
    @discardableResult
    func create(in database: Database) async throws -> Self {
        try await self.create(on: database).get()
        return self
    }
    
    /// Asynchronously saves the model in the database.
    /// - Parameter database: The database connection to perform the save on
    /// - Returns: The saved model instance
    /// - Throws: Any database errors that occur during the save operation
    @discardableResult
    func save(in database: Database) async throws -> Self {
        try await self.save(on: database).get()
        return self
    }
    
    /// Asynchronously deletes the model from the database.
    /// - Parameters:
    ///   - database: The database connection to perform the delete on
    ///   - force: When true, performs a force delete. Defaults to false
    /// - Returns: The deleted model instance
    /// - Throws: Any database errors that occur during the delete operation
    @discardableResult
    func delete(from database: Database, force: Bool = false) async throws -> Self {
        try await self.delete(force: force, on: database).get()
        return self
    }
    
    /// Asynchronously restores a soft-deleted model in the database.
    /// - Parameter database: The database connection to perform the restore on
    /// - Returns: The restored model instance
    /// - Throws: Any database errors that occur during the restore operation
    @discardableResult
    func restore(in database: Database) async throws -> Self {
        try await self.restore(on: database).get()
        return self
    }
}
