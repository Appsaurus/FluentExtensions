import Foundation
import Fluent
import VaporExtensions

public extension Model {
    
    @discardableResult
        func update(in database: Database, force: Bool = true) async throws -> Self {
            if force {
                self._$id.exists = force
            }
            try await self.update(in: database)
            return self
        }

        @discardableResult
        func upsert(in database: Database) async throws -> Self {
            if let _ = try await existingEntityWithId(on: database) {
                self._$id.exists = true
                return try await self.update(in: database, force: true)
            } else {
                return try await self.create(in: database)
            }
        }

        @discardableResult
        func replace(with model: Self, on database: Database) async throws -> Self {
            try await self.delete(on: database)
            return try await model.create(in: database)
        }

        @discardableResult
        func updateIfExists(in database: Database) async throws -> Self {
            let existingEntity = try await assertExistingEntityWithId(on: database)
            return try await existingEntity.update(in: database, force: true)
        }
}
