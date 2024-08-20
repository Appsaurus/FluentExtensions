//
//  FluentController.swift
//  
//
//  Created by Brian Strobach on 8/16/24.
//


public typealias FluentResourceModel = Fluent.Model & ResourceModel

open class FluentController<Resource: FluentResourceModel,
                            Create: CreateModel,
                            Read: ReadModel,
                            Update: UpdateModel>: Controller<Resource, Create, Read, Update> {
    
 
    
    open override func readAllModels(in db: Database) async throws -> [Resource] {
        return try await Resource.query(on: db).all()
    }
    
    open override func create(model: Resource, in db: Database) async throws -> Resource {
        try await model.create(on: db)
        return model
    }
    
    open override func update(model: Resource, in db: Database) async throws -> Resource {
        try await model.update(in: db)
    }

    
    open override func delete(model: Resource, in db: Database, force: Bool = false) async throws -> Resource {
        try await model.delete(from: db, force: force)
    }
    
    open override func save(model: Resource, in db: Database) async throws -> Resource {
        try await model.save(in: db)        
    }
    
    open override func upsert(model: Resource, in db: Database) async throws -> Resource {
        try await model.upsert(in: db)
    }
    
    
    open override func create(models: [Resource], in db: Database) async throws -> [Resource] {
        try await models.create(in: db)
    }
    
    open override func update(models: [Resource], in db: Database) async throws -> [Resource] {
        try await models.update(in: db)
    }
    
    open override func delete(models: [Resource], 
                              in db: Database,
                              force: Bool = false) async throws -> [Resource] {
        try await models.delete(from: db, force: force)
    }
    
    open override func save(models: [Resource], in db: Database) async throws -> [Resource] {
        try await models.save(in: db)
    }
    
    open override func upsert(models: [Resource], in db: Database) async throws -> [Resource] {
        try await models.update(in: db)
//        try await db.performBatch(action: self.update, on: models)
    }
    
    //MARK: Other
    
//    open override func update(model: Resource,
//                              with updateModel: Update,
//                              in db: Database) async throws -> Resource {
//
//    }
        
}

extension FluentController where Resource == Create {
    public func convert(_ create: Create) throws -> Resource {
        return create
    }
}

extension FluentController where Resource == Update {
    @discardableResult
    public func apply(_ update: Update, to model: Resource) throws -> Resource {
        return update
    }
    
    public func update(model: Resource,
                              with updateModel: Update,
                              in db: Database) async throws -> Resource {
        return updateModel
    }
}

extension FluentController where Resource == Read {
    public func read(_ model: Resource) throws -> Read {
        return model
    }
}

extension FluentController where Resource.ResolvedParameter == Resource.IDValue {
    public func readModel(id: Resource.IDValue, in db: Database) async throws -> Resource {
        return try await Resource.find(id, on: db).unwrapped(or: Abort(.notFound))
    }
}
