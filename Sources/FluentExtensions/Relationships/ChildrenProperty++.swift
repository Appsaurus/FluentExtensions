import Vapor
import Fluent

public extension ChildrenProperty {
    /// Returns true if the supplied model is a child
    /// to this relationship.
    func includes(_ model: To, in database: Database) async throws -> Bool {
        let id = try model.requireID()
        return try await query(on: database)
            .filter(\._$id == id)
            .first() != nil
    }

    func all(in database: Database) async throws -> [To] {
        try await query(on: database).all()
    }

    @discardableResult
    func attach(_ children: [To], in database: Database) async throws -> [To] {
        guard let id = fromId else {
            fatalError("Cannot query children relation from unsaved model.")
        }
        children.forEach {
            switch self.parentKey {
            case .required(let keyPath):
                $0[keyPath: keyPath].id = id
            case .optional(let keyPath):
                $0[keyPath: keyPath].id = id
            }
        }
        return try await children.update(in: database)
    }

    @discardableResult
    func replace(with children: [To], in database: Database) async throws -> [To] {
        let existingChildren = try await self.all(in: database)
        switch self.parentKey {
        case .required(_):
            try await existingChildren.delete(from: database, force: true)
            return try await children.upsert(in: database)
        case .optional(let keyPath):
            existingChildren.forEach { $0[keyPath: keyPath].id = nil }
            children.forEach { $0[keyPath: keyPath].$id.value = self.fromId }
            try await existingChildren.update(in: database)
            return try await children.upsert(in: database)
        }
    }
}

public extension Model {
    /// Returns true if this model is a child
    /// to the supplied relationship.
    func isChild<M: Model>(_ children: ChildrenProperty<M, Self>, in database: Database) async throws -> Bool {
        try await children.includes(self, in: database)
    }

    @discardableResult
    func replaceChildren<C: Model>(
        with children: [C],
        through childKeyPath: ChildrenPropertyKeyPath<Self, C>,
        in database: Database
    ) async throws -> [C] {
        let _ = try self.requireID()
        return try await database.transaction { database in
            let relation = self[keyPath: childKeyPath]
            return try await relation.replace(with: children, in: database)
        }
    }
}
