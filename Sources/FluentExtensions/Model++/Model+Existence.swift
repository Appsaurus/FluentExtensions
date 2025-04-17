import Vapor
import Fluent

// MARK: - Existence checks
public extension Model {
    /// Attempts to find an existing entity with the same ID as the current instance
    /// - Parameter database: The database connection to search in
    /// - Returns: The existing entity if found, nil otherwise
    /// - Throws: Any database errors that occur during the search
    func existingEntityWithId(on database: Database) async throws -> Self? {
        guard let id = self.id else {
            return nil
        }
        return try await Self.find(id, on: database)
    }

    /// Finds and returns an existing entity with the same ID as the current instance
    /// - Parameter database: The database connection to search in
    /// - Returns: The existing entity
    /// - Throws: An abort error if the entity doesn't exist, or any database errors
    @discardableResult
    func assertExistingEntityWithId(on database: Database) async throws -> Self {
        guard let existingEntity = try await existingEntityWithId(on: database) else {
            throw Abort(.notFound, reason: "An entity with that ID could not be found.")
        }
        return existingEntity
    }
}

public extension Collection where Element: Model {
    /// Verifies the existence of multiple entities in the database
    /// - Parameter database: The database connection to search in
    /// - Returns: Array of existing entities
    /// - Throws: An error if any entity doesn't exist, or any database errors
    @discardableResult
    func assertExistingEntitiesWithIds(on database: Database) async throws -> [Element] {
        try await withThrowingTaskGroup(of: Element.self) { group in
            for entity in self {
                group.addTask {
                    try await entity.assertExistingEntityWithId(on: database)
                }
            }
            
            var entities: [Element] = []
            for try await entity in group {
                entities.append(entity)
            }
            return entities
        }
    }
}
