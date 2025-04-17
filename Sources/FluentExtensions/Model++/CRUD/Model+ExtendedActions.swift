import Foundation
import Fluent
import VaporExtensions

public extension Model {
    /// Updates an existing model in the database with optional force flag.
    /// - Parameters:
    ///   - database: The database connection to perform the update on
    ///   - force: When true, marks the model as existing before update. Defaults to true
    /// - Returns: The updated model instance
    /// - Throws: Any database errors that occur during the update operation
    @discardableResult
    func update(in database: Database, force: Bool = true) async throws -> Self {
        if force {
            self._$id.exists = force
        }
        try await self.update(in: database)
        return self
    }
    
    /// Creates or updates a model in the database based on whether it already exists.
    /// - Parameter database: The database connection to perform the operation on
    /// - Returns: The created or updated model instance
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    func upsert(in database: Database) async throws -> Self {
        if let _ = try await existingEntityWithId(on: database) {
            return try await self.update(in: database, force: true)
        } else {
            return try await self.create(in: database)
        }
    }
    
    /// Deletes the current model and creates a new one with the provided model data.
    /// - Parameters:
    ///   - model: The new model instance to create after deletion
    ///   - database: The database connection to perform the operations on
    /// - Returns: The newly created model instance
    /// - Throws: Any database errors that occur during the delete or create operations
    @discardableResult
    func replace(with model: Self, on database: Database) async throws -> Self {
        try await self.delete(on: database)
        return try await model.create(in: database)
    }
    
    /// Updates a model only if it exists in the database.
    /// - Parameter database: The database connection to perform the update on
    /// - Returns: The updated model instance
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    func updateIfExists(in database: Database) async throws -> Self {
        let existingEntity = try await assertExistingEntityWithId(on: database)
        return try await existingEntity.update(in: database, force: true)
    }
}
