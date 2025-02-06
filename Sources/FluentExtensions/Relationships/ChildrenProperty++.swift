import Vapor
import Fluent

public struct ChildrenDiff<T: Model> {
    let modelsToUpdate: [T]
    let modelsToCreate: [T]
    let modelsToRemove: [T]
}

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
    func markForAttachment(_ children: [To]) throws -> [To] {
        
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
        return children
    }
    
    @discardableResult
    func attach(_ children: [To],
                updatingBy method: UpdateMethod = .upsert,
                in database: Database) async throws -> [To] {
        let children = try markForAttachment(children)
        return try await children.updateBy(method, in: database)
    }
    
    
    @discardableResult
    func markForDetachment(_ children: [To]) throws -> [To] {
        
        switch self.parentKey {
        case .required(_):
            throw Abort(.badRequest, reason: "That parent child relationship is required.")
        case .optional(let keyPath):
            children.forEach { $0[keyPath: keyPath].id = nil }
        }
        return children
    }
    
    @discardableResult
    func detach(_ children: [To], in database: Database) async throws -> [To] {
        return try await markForDetachment(children)
            .update(in: database, force: true)
    }
    
    func detachAll(on database: Database) async throws {
        guard let fromID = self.fromId else {
            fatalError("Cannot detach siblings relation \(self.name) from unsaved model.")
        }
        var existingChildren = try await self.all(in: database)
        existingChildren = try markForDetachment(existingChildren)
        
        try await existingChildren.update(in: database)
    }
    
    func remove(children: [To], by removalMethod: RemovalMethod = .detach, in database: Database) async throws {
        switch removalMethod {
        case .delete(let force):
            try await children.delete(force: force, on: database)
        case .detach:
            try await self.detach(children, in: database)
        }
    }
    


//    func markForReplacement(_ children: [To], force: Bool = false, in database: Database) async throws -> ([To], [To]) {
//        switch (self.parentKey, force) {
//        case (.required(_), false):
//            throw Abort(.badRequest, reason: "That parent child relationship is required.")
//        default:
//            break
//        }
//        
//        var existingChildren = try await self.all(in: database)
//        existingChildren = try markForDetachment(existingChildren)
//        let children = try markForAttachment(children)
//        return (existingChildren, children)
//    }
//    @discardableResult
//    func replace(with children: [To], force: Bool = false, in database: Database) async throws -> [To] {
//        let resources = try await markForReplacement(children, force: force, in: database)
//        let existingChildren = resources.0
//        let children = resources.1
//        
//        try await existingChildren.update(in: database, force: force)
//        return try await children.upsert(in: database)
//    }
//
//    @discardableResult
//    func replace(
//        with children: [To],
//        by removalMethod: RemovalMethod = .detach,
//        updatingBy updateMethod: UpdateMethod = .upsert,
//        on database: Database) async throws -> [To] {
//        return try await database.transaction { database in
//            switch removalMethod {
//            case .delete(let force):
//                try await self.query(on: database).delete(force: force)
//            case .detach:
//                try await self.detachAll(on: database)
//            }
//            return try await self.attach(children, updatingBy: .upsert, in: database)
//        }
//        
//    }
    
    func diffWithExistingChildren(_ newChildren: [To], in database: Database) async throws -> ChildrenDiff<To> {
        let existingChildren = try await self.all(in: database)
        
        // Split new children into those with and without IDs
        let (newWithIds, newWithoutIds) = newChildren.reduce(into: ([To](), [To]())){ result, model in
            if (try? model.requireID()) != nil {
                result.0.append(model)
            } else {
                result.1.append(model)
            }
        }
        
        // Get existing IDs safely
        let existingIds = try existingChildren.map { try $0.requireID() }
        let newIds = try newWithIds.map { try $0.requireID() }
        
        let modelsToUpdate = newWithIds.filter { model in
            guard let id = try? model.requireID() else { return false }
            return existingIds.contains(id)
        }
        
        // All models without IDs need to be created
        let modelsToCreate = newWithoutIds + newWithIds.filter { model in
            guard let id = try? model.requireID() else { return true }
            return !existingIds.contains(id)
        }
        
        let modelsToRemove = existingChildren.filter { model in
            guard let id = try? model.requireID() else { return false }
            return !newIds.contains(id)
        }
        
        return ChildrenDiff(
            modelsToUpdate: modelsToUpdate,
            modelsToCreate: modelsToCreate,
            modelsToRemove: modelsToRemove
        )
    }

    @discardableResult
    func replace(
        with children: [To],
        deleteOrphaned: Bool = true,
        in database: Database
    ) async throws -> [To] {
        try await database.transaction { database in
            let diff = try await self.diffWithExistingChildren(children, in: database)
            
            // Handle removals
            for model in diff.modelsToRemove {
                switch self.parentKey {
                case .required(_):
                    if deleteOrphaned {
                        try await model.delete(force: true, on: database)
                    } else {
                        throw Abort(.badRequest, reason: "Cannot remove child with required parent relationship unless deleteOrphaned is true")
                    }
                case .optional(_):
                    try await self.detach([model], in: database)
                }
            }
            
            let modelsToUpsert = diff.modelsToUpdate + diff.modelsToCreate
            try self.markForAttachment(modelsToUpsert)
            return try await modelsToUpsert.upsert(in: database)
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
