////
////  CrudController.swift
////  App
////
////  Created by Brian Strobach on 1/21/21.
////


import RuntimeExtensions
import VaporExtensions
import CollectionConcurrencyKit

open class Controller<Resource: ResourceModel,
                      Create: CreateModel,
                      Read: ReadModel,
                      Update: UpdateModel,
                      SearchResult: SearchResultModel>: RouteCollection {
    open var config: Config
    
    public init(config: Config = Config()) {
        self.config = config
    }
    
    public convenience init(_ modifier: (Config) -> ()) {
        self.init()
        modifier(self.config)
    }
    
    //MARK: Routes
    open func boot(routes: RoutesBuilder) throws {
        try registerRoutes(routes: routes)
    }
    
    open func registerRoutes(routes: RoutesBuilder) throws {
        let router = routes.grouped(config.baseRoute.pathComponents)
        try registerCRUDRoutes(routes: router)
    }
    
    open func registerCRUDRoutes(routes: RoutesBuilder) throws {
        let supportedActions = config.supportedActions.supportedActions
        
        if supportedActions.contains(.search) {
            routes.get(use: search)
        }
        if supportedActions.contains(.read) {
            routes.get(":id", use: read)
        }
        if supportedActions.contains(.readAll) {
            routes.get("all", use: readAll)
        }
        if supportedActions.contains(.create) {
            routes.post(use: create)
        }
        if supportedActions.contains(.createBatch) {
            routes.post("batch", use: createBatch)
        }
        if supportedActions.contains(.update) {
            routes.put(use: update)
            routes.put(":id", use: update)
        }
        if supportedActions.contains(.updateBatch) {
            routes.put("batch", use: updateBatch)
        }
        if supportedActions.contains(.delete) {
            routes.delete(":id", use: delete)
        }
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
        try await assertRequest(req, isAuthorizedTo: .read, model)
        return try read(model)
    }
    
    open func readAll(_ req: Request) async throws -> [Read] {
        let models = try await readAllModels(in: req.db)
        try await assertRequest(req, isAuthorizedTo: .readAll, models)
        return try models.map(read)
    }
    
    //MARK: Create Routes
    open func create(_ req: Request) async throws -> Read {
        let model = try req.content.decode(Create.self)
        let resource = try convert(model)
        try await assertRequest(req, isAuthorizedTo: .create, resource)
        let method = try? req.query.get(CreateMethod.self, at: "method")
        return try await self.create(createModel: model, in: req.db, method: method)
    }
    
    open func createBatch(_ req: Request) async throws -> [Read] {
        let models = try req.content.decode([Create].self)
        let resources = try models.map(convert)
        try await assertRequest(req, isAuthorizedTo: .createBatch, resources)
        return try await self.create(createModels: models, in: req.db)
    }
    
    //MARK: Update
    open func update(_ req: Request) async throws -> Read {
        let updateModel = try req.content.decode(Update.self)
        let resourceID = try req.parameters.next(Resource.self)
        let resource = try await readModel(id: resourceID, in: req.db)
        try await assertRequest(req, isAuthorizedTo: .update, resource)
        let updatedResource = try await update(model: resource,
                                           with: updateModel,
                                           in: req.db)
        return try read(updatedResource)
    }

    open func updateBatch(_ req: Request) async throws -> [Read] {
        let updateModels = try req.content.decode([Update].self)
        return try await updateModels.asyncMap({try await self.update(updateModel: $0, on: req)})
    }
    
    //MARK: Delete
    
    open func delete(_ req: Request) async throws -> Read {
        let resourceID = try req.parameters.next(Resource.self)
        let resource = try await self.readModel(id: resourceID, in: req.db)
        try await assertRequest(req, isAuthorizedTo: .delete, resource)
        let forceDelete = (try? req.query.get(Bool.self, at: "force")) ?? config.forceDelete
        let deletedModel = try await self.delete(model: resource, in: req.db, force: forceDelete)
        return try read(deletedModel)
    }
    
    //MARK: End Routes
    
    open func assertRequest(_ req: Request, isAuthorizedTo action: Controller.Action, _ resource: Resource) async throws {
        guard try await request(req, isAuthorizedTo: action, resource) else {
            throw Abort(.unauthorized)
        }
    }
    
    //MARK: Access Control
    open func request(_ req: Request, isAuthorizedTo action: Controller.Action, _ resource: Resource) async throws -> Bool {
        // Check if there's a custom single-resource access handler
        if let accessHandler = config.accessControl.resource[action] {
            return try await accessHandler(req, resource)
        }
        
        // Fall back to default implementations
        switch action {
        case .search:
            return try await request(req, canSearch: resource)
        case .read:
            return try await request(req, canRead: resource)
        case .readAll:
            return try await request(req, canReadAll: resource)
        case .create:
            return try await request(req, canCreate: resource)
        case .createBatch:
            return try await request(req, canCreateBatch: resource)
        case .update:
            return try await request(req, canUpdate: resource)
        case .updateBatch:
            return try await request(req, canUpdateBatch: resource)
        case .delete:
            return try await request(req, canDelete: resource)
        }
    }

    open func assertRequest(_ req: Request, isAuthorizedTo action: Controller.Action, _ resources: [Resource]) async throws {
        guard try await request(req, isAuthorizedTo: action, resources) else {
            throw Abort(.unauthorized)
        }
    }
    open func request(_ req: Request, isAuthorizedTo action: Controller.Action, _ resources: [Resource]) async throws -> Bool {
        // Check if there's a custom batch access handler
        if let accessHandler = config.accessControl.resources[action] {
            return try await accessHandler(req, resources)
        }
        
        // Fall back to checking each resource individually
        for resource in resources {
            guard try await request(req, isAuthorizedTo: action, resource) else {
                return false
            }
        }
        return true
    }

    open func request(_ req: Request, canSearch resource: Resource) async throws -> Bool {
        return true
    }

    open func request(_ req: Request, canRead resource: Resource) async throws -> Bool {
        return true
    }

    open func request(_ req: Request, canReadAll resource: Resource) async throws -> Bool {
        return true
    }

    open func request(_ req: Request, canCreate resource: Resource) async throws -> Bool {
        return true
    }

    open func request(_ req: Request, canCreateBatch resource: Resource) async throws -> Bool {
        return true
    }

    open func request(_ req: Request, canUpdate resource: Resource) async throws -> Bool {
        return true
    }

    open func request(_ req: Request, canUpdateBatch resource: Resource) async throws -> Bool {
        return true
    }

    open func request(_ req: Request, canDelete resource: Resource) async throws -> Bool {
        return true
    }
    
    //MARK: End Access Control
    
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
        try await assertRequest(req, isAuthorizedTo: .update, resource)
        let updatedResource = try await update(model: resource,
                                               with: updateModel,
                                               in: req.db)
        return try read(updatedResource)
    }
    
    open func update(updateModels: [Update], on req: Request) async throws -> [Read] {
        return try await updateModels.asyncMap({try await self.update(updateModel: $0, on: req)})
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
