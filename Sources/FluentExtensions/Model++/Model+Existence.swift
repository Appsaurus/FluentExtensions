import Vapor
import Fluent

// MARK: - Existence checks
public extension Model {
    func existingEntityWithId(on database: Database) async throws -> Self? {
        guard let id = self.id else {
            return nil
        }
        return try await Self.find(id, on: database)
    }

    @discardableResult
    func assertExistingEntityWithId(on database: Database) async throws -> Self {
        guard let existingEntity = try await existingEntityWithId(on: database) else {
            throw Abort(.notFound, reason: "An entity with that ID could not be found.")
        }
        return existingEntity
    }
}

public extension Collection where Element: Model {
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
