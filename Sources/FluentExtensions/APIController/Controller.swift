////
////  CrudController.swift
////  App
////
////  Created by Brian Strobach on 1/21/21.
////


import RuntimeExtensions
import VaporExtensions
import CollectionConcurrencyKit

public enum CreateMethod: Decodable {
    case create
    case save
    case upsert
    static var `default` = CreateMethod.create
}

public enum UpdateMethod: Decodable {
    case update
    case save
    case upsert
    static var `default` = UpdateMethod.update
}

public class ControllerSettings {
    public var forceDelete: Bool
    
    public init(forceDelete: Bool = true) {
        self.forceDelete = forceDelete
    }
    
}

public typealias ResourceModel = Content & Parameter
public typealias CreateModel = Content
public typealias ReadModel = Content
public typealias UpdateModel = Content
public typealias SearchResultModel = Content

open class Controller<Resource: ResourceModel,
                      Create: CreateModel,
                      Read: ReadModel,
                      Update: UpdateModel,
                      SearchResult: SearchResultModel> {
    var baseRoute: [PathComponentRepresentable]
    var middlewares: [Middleware]
    var settings: ControllerSettings
    
    public init(baseRoute: [PathComponentRepresentable], 
                middlewares: [Middleware] = [],
                settings: ControllerSettings = ControllerSettings()) {
        self.baseRoute = baseRoute
        self.middlewares = middlewares
        self.settings = settings
    }
    
    open func performBatch(
        action: @escaping AsyncBatchAction<Resource, Resource>,
        on resources: [Resource],
        in database: Database,
        transaction: Bool = true,
        concurrently: Bool = true
    ) async throws -> [Resource] {
        return try await database.performBatch(action: action,
                                               on: resources,
                                               transaction: transaction,
                                               concurrently: concurrently)
    }
    

    //MARK: Routes
    
    open func registerRoutes(routes: RoutesBuilder) throws {
        let router = routes.grouped(baseRoute.pathComponents)
        try registerCRUDRoutes(routes: router)
    }
    
    open func registerCRUDRoutes(routes: RoutesBuilder) throws {
        
        routes.get(use: search)
        routes.get(":id", use: read)
        routes.get("all", use: readAll)
        routes.post(use: create)
        routes.post("batch", use: createBatch)
        routes.put(use: update)
        routes.put(":id", use: update)
        routes.put("batch", use: updateBatch)
        routes.delete(":id", use: delete)
    }
    
    //MARK: Begin Routes
    
    //MARK: Search Routes
    open func search(_ req: Request) async throws -> SearchResult {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    //MARK: Read Routes
    open func read(_ req: Request) async throws -> Read {
        let resourceID = try req.parameters.next(Resource.self)
        let model = try await readModel(id: resourceID, in: req.db)
        return try read(model)
    }
    
    
    
    open func readAll(on req: Request) async throws -> [Read] {
        try await readAllModels(in: req.db).map(read)
    }
    
    //MARK: Create Routes
    open func create(_ req: Request) async throws -> Read {
        let model = try req.content.decode(Create.self)
        let method = try? req.query.get(CreateMethod.self, at: "method")
        return try await self.create(createModel: model, in: req.db, method: method)
    }
    
    open func createBatch(_ req: Request) async throws -> [Read] {
        let models = try req.content.decode([Create].self)
        return try await self.create(createModels: models, in: req.db)
    }
    
    //MARK: Update
    open func update(_ req: Request) async throws -> Read {
        let model = try req.content.decode(Update.self)
        return try await self.update(updateModel: model, on: req)
    }

    open func updateBatch(_ req: Request) async throws -> [Read] {
        let models = try req.content.decode([Update].self)
        return try await self.update(updateModels: models, on: req)
    }
    
    //MARK: Delete
    
    open func delete(_ req: Request) async throws -> Read {
        let resourceID = try req.parameters.next(Resource.self)
        let model = try await self.readModel(id: resourceID, in: req.db)
        let forceDelete = (try? req.query.get(Bool.self, at: "force")) ?? settings.forceDelete
        let deletedModel = try await self.delete(model: model, in: req.db, force: forceDelete)
        return try read(deletedModel)
    }
    
    //MARK: End Routes
    
    
    open func create(resource: Resource,
                     in db: Database,
                     method: CreateMethod) async throws -> Resource {
        switch method {
            case .create:
            return try await create(model: resource, in: db)
            case .upsert:
            return try await upsert(model: resource, in: db)
            case .save:
            return try await save(model: resource, in: db)
        }
    }
    
    open func update(resource: Resource,
                     in db: Database,
                     method: UpdateMethod) async throws -> Resource {
        switch method {
            case .update:
            return try await update(model: resource, in: db)
            case .upsert:
            return try await upsert(model: resource, in: db)
            case .save:
            return try await save(model: resource, in: db)
        }
    }
    
    open func create(resources: [Resource],
                     in db: Database,
                     method: CreateMethod) async throws -> [Resource] {
        return try await db.performBatch(action: self.create, on: resources)
    }
    
    open func update(resources: [Resource],
                     in db: Database,
                     method: UpdateMethod) async throws -> [Resource] {
        return try await db.performBatch(action: self.update, on: resources)
    }



    
    open func create(createModel: Create, 
                     in db: Database,
                     method: CreateMethod? = nil) async throws -> Read {
        let method = method ?? .default
        var resource = try convert(createModel)
        switch method {
            case .create:
            resource = try await create(model: resource, in: db)
            case .upsert:
            resource = try await upsert(model: resource, in: db)
            case .save:
            resource = try await save(model: resource, in: db)
        }
        return try read(resource)
    }

    open func create(createModels: [Create], 
                     in db: Database,
                     method: CreateMethod? = nil) async throws -> [Read] {
        let method = method ?? .default
        var models = try createModels.map(convert)
        switch method {
            case .create:
            models = try await create(models: models, in: db)
            case .upsert:
            models = try await create(models: models, in: db)
            case .save:
            models = try await create(models: models, in: db)
        }
        return try models.map(read)
    }
    

    open func update(updateModel: Update, on req: Request) async throws -> Read {
//        let updatedModel = try await update(updateModel: updateModel, on: req)
        let resourceID = try req.parameters.next(Resource.self)
        let resource = try await readModel(id: resourceID, in: req.db)
        let updatedResource = try await update(model: resource,
                                               with: updateModel,
                                               in: req.db)
        return try read(updatedResource)
    }
    
    open func update(updateModels: [Update], on req: Request) async throws -> [Read] {
        return try await updateModels.asyncMap({try await self.update(updateModel: $0, on: req)})
    }

    //MARK: Abstact methods
    
    //MARK: Abstact conversions
    open func convert(_ create: Create) throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    @discardableResult
    open func apply(_ update: Update, to model: Resource) throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func read(_ model: Resource) throws -> Read {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    //MARK: Abstract actions
    open func readModel(id: Resource.ResolvedParameter, in db: Database) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func readAllModels(in db: Database) async throws -> [Resource] {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func create(model: Resource, in db: Database) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func update(model: Resource, in db: Database) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }

    
    open func delete(model: Resource, in db: Database, force: Bool = false) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func save(model: Resource, in db: Database) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func upsert(model: Resource, in db: Database) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    
    open func create(models: [Resource], in db: Database) async throws -> [Resource] {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func update(models: [Resource], in db: Database) async throws -> [Resource] {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func delete(models: [Resource], in db: Database, force: Bool = false) async throws -> [Resource] {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func save(models: [Resource], in db: Database) async throws -> [Resource] {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func upsert(models: [Resource], in db: Database) async throws -> [Resource] {
        return try await db.performBatch(action: self.update, on: models)
    }
    
    //MARK: Other
    
    open func update(model: Resource,
                     with updateModel: Update,
                     in db: Database) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
        
    //MARK: End abstact methods
}
