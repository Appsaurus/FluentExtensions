import Vapor
import Fluent

/// Represents the changes to be made to a collection of child models
public struct ChildrenDiff<T: Model> {
    let modelsToUpdate: [T]
    let modelsToCreate: [T]
    let modelsToRemove: [T]
}

public extension ChildrenProperty {
    /// Checks if a specific model is included in the children relationship
    /// - Parameters:
    ///   - model: The model to check for
    ///   - database: The database to perform the check on
    /// - Returns: Boolean indicating if the model is included
    func includes(_ model: To, in database: Database) async throws -> Bool {
        let id = try model.requireID()
        return try await query(on: database)
            .filter(\._$id == id)
            .first() != nil
    }

    /// Retrieves all children in the relationship
    /// - Parameter database: The database to query
    /// - Returns: Array of child models
    func all(in database: Database) async throws -> [To] {
        try await query(on: database).all()
    }

    /// Marks models for attachment to the parent
    /// - Parameter children: The children to mark for attachment
    /// - Returns: The modified children array
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
    
    /// Attaches children to the parent
    /// - Parameters:
    ///   - children: The children to attach
    ///   - method: The method to use for updating
    ///   - database: The database to perform the operation on
    /// - Returns: The attached children
    @discardableResult
    func attach(_ children: [To],
                updatingBy method: UpdateMethod = .upsert,
                in database: Database) async throws -> [To] {
        let children = try markForAttachment(children)
        return try await children.updateBy(method, in: database)
    }
    
    /// Marks children for detachment from the parent
    /// - Parameter children: The children to mark for detachment
    /// - Returns: The modified children array
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
    
    /// Detaches children from the parent
    /// - Parameters:
    ///   - children: The children to detach
    ///   - database: The database to perform the operation on
    /// - Returns: The detached children
    @discardableResult
    func detach(_ children: [To], in database: Database) async throws -> [To] {
        return try await markForDetachment(children)
            .update(in: database, force: true)
    }
    
    /// Detaches all children from the parent
    /// - Parameter database: The database to perform the operation on
    func detachAll(on database: Database) async throws {
        guard let fromID = self.fromId else {
            fatalError("Cannot detach siblings relation \(self.name) from unsaved model.")
        }
        var existingChildren = try await self.all(in: database)
        existingChildren = try markForDetachment(existingChildren)
        
        try await existingChildren.update(in: database)
    }
    
    /// Removes children using the specified removal method
    /// - Parameters:
    ///   - children: The children to remove
    ///   - removalMethod: The method to use for removal
    ///   - database: The database to perform the operation on
    func remove(children: [To], by removalMethod: RemovalMethod = .detach, in database: Database) async throws {
        switch removalMethod {
        case .delete(let force):
            try await children.delete(force: force, on: database)
        case .detach:
            try await self.detach(children, in: database)
        }
    }
    
    /// Analyzes the differences between existing and new children
    /// - Parameters:
    ///   - newChildren: The new set of children
    ///   - database: The database to perform the comparison on
    /// - Returns: A ChildrenDiff containing the changes to be made
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

    /// Replaces all children with a new set
    /// - Parameters:
    ///   - children: The new set of children
    ///   - deleteOrphaned: Whether to delete orphaned children
    ///   - database: The database to perform the operation on
    /// - Returns: The updated set of children
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
    /// Checks if the model is a child in the specified relationship
    /// - Parameters:
    ///   - children: The children relationship to check
    ///   - database: The database to perform the check on
    /// - Returns: Boolean indicating if the model is a child
    func isChild<M: Model>(_ children: ChildrenProperty<M, Self>, in database: Database) async throws -> Bool {
        try await children.includes(self, in: database)
    }

    /// Replaces children in a specific relationship
    /// - Parameters:
    ///   - children: The new children to set
    ///   - childKeyPath: The key path to the children relationship
    ///   - database: The database to perform the operation on
    /// - Returns: The updated children array
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
