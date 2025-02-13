////
////  Controller.swift
////  App
////
////  Created by Brian Strobach on 1/21/21.
////


import RuntimeExtensions
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
    
    //MARK: Register Routes
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
            if config.putAction == .update {
                routes.put(use: update)
                routes.put(":id", use: update)
            }
            else {
                routes.put("update", use: update)
                routes.put(["update", ":id"], use: update)
            }
        }
        
        if supportedActions.contains(.updateBatch) {
            if config.putAction == .update {
                routes.put("batch", use: updateBatch)
            }
            else {
                routes.put(["update", "batch"], use: updateBatch)
            }
        }
        
        if supportedActions.contains(.save) {
            if config.putAction == .save {
                routes.put(use: save)
                routes.put(":id", use: save)
            }
            else {
                routes.put("save", use: save)
                routes.put(["save", ":id"], use: save)
            }
            
        }
        if supportedActions.contains(.saveBatch) {
            if config.putAction == .save {
                routes.put("batch", use: saveBatch)
            }
            else {
                routes.put(["save", "batch"], use: saveBatch)
            }
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
    
    //NOTE: Async auth checks on each of these individually could cause a lot of lookups.
    //Monitor and write one-off implementations or workarounds as need.
    
    //MARK: Read Routes
    open func read(_ req: Request) async throws -> Read {
        let resourceID = try req.parameters.next(Resource.self)
        let model = try await readModel(id: resourceID, request: req)
        try await assertRequest(req, isAuthorizedTo: .read, model)
        return try read(model)
    }
    
    open func readAll(_ req: Request) async throws -> [Read] {
        let models = try await readAllModels(request: req)
        try await assertRequest(req, isAuthorizedTo: .read, models)
        return try models.map(read)
    }
    
    //MARK: Create Routes
    open func create(_ req: Request) async throws -> Read {
        let model = try req.content.decode(Create.self)
        let resource = try convert(model)
        try await assertRequest(req, isAuthorizedTo: .create, resource)
        return try await self.create(createModel: model, request: req)
    }
    
    open func createBatch(_ req: Request) async throws -> [Read] {
        let models = try req.content.decode([Create].self)
        let resources = try models.map(convert)
        try await assertRequest(req, isAuthorizedTo: .create, resources)
        return try await self.create(createModels: models, request: req)
    }
    
    open func create(createModel: Create, request: Request) async throws -> Read {
        var resource = try convert(createModel)
        try await assertRequest(request, isAuthorizedTo: .create, resource)
        resource = try await create(resource: resource, request: request)
        return try read(resource)
    }
    
    open func create(createModels: [Create], request: Request) async throws -> [Read] {
        var resources = try createModels.map(convert)
        try await assertRequest(request, isAuthorizedTo: .create, resources)
        return try await create(resources: resources, request: request).map(read)
    }
    
    
    //MARK: Update
    open func update(_ req: Request) async throws -> Read {
        let updateModel = try req.content.decode(Update.self)
        return try await update(updateModel: updateModel, on: req)
    }
    
    open func updateBatch(_ req: Request) async throws -> [Read] {
        let updateModels = try req.content.decode([Update].self)
        return try await self.update(updateModels: updateModels, on: req)
    }
    
    
    open func update(updateModel: Update, on req: Request) async throws -> Read {
        let resourceID = try req.parameters.next(Resource.self)
        let resource = try await readModel(id: resourceID, request: req)
        try await assertRequest(req, isAuthorizedTo: .update, resource)
        let updatedResource = try await update(resource: resource,
                                               with: updateModel,
                                               request: req)
        return try read(updatedResource)
    }
    
    open func update(updateModels: [Update], on req: Request) async throws -> [Read] {
        return try await updateModels.asyncMap({try await self.update(updateModel: $0, on: req)})
    }
    
    //MARK: Save
    open func save(_ req: Request) async throws -> Read {
        let saveModel = try req.content.decode(Create.self)
        return try await save(saveModel: saveModel, on: req)
    }
    
    open func saveBatch(_ req: Request) async throws -> [Read] {
        let saveModels = try req.content.decode([Create].self)
        return try await saveModels.asyncMap({try await self.save(saveModel: $0, on: req)})
    }
    
    
    open func save(saveModel: Create, on req: Request) async throws -> Read {
        let resourceID = try req.parameters.next(Resource.self)
        let resource = try await readModel(id: resourceID, request: req)
        try await assertRequest(req, isAuthorizedTo: .save, resource)
        let savedResource = try await save(resource: resource, request: req)
        return try read(savedResource)
    }
    
    open func save(saveModels: [Create], on req: Request) async throws -> [Read] {
        return try await saveModels.asyncMap({try await self.save(saveModel: $0, on: req)})
    }
    
    //MARK: Delete
    
    open func delete(_ req: Request) async throws -> Read {
        let resourceID = try req.parameters.next(Resource.self)
        let resource = try await self.readModel(id: resourceID, request: req)
        try await assertRequest(req, isAuthorizedTo: .delete, resource)
        let forceDelete = (try? req.query.get(Bool.self, at: "force")) ?? config.forceDelete
        let deletedModel = try await self.delete(resource: resource, request: req, force: forceDelete)
        return try read(deletedModel)
    }
    
    //MARK: End Routes
    
    open func assertRequest(_ req: Request, isAuthorizedTo action: AuthorizedAction, _ resource: Resource) async throws {
        guard try await request(req, isAuthorizedTo: action, resource) else {
            throw Abort(.unauthorized)
        }
    }
    
    //MARK: Access Control
    open func request(_ req: Request, isAuthorizedTo action: AuthorizedAction, _ resource: Resource) async throws -> Bool {
        // First check injected access control
        if let accessHandler = config.accessControl.resource[action] {
            guard try await accessHandler(req, resource) else {
                return false
            }
        }
        
        // Then check internal authorization
        switch action {
        case .read:
            return try await request(req, canRead: resource)
        case .create:
            return try await request(req, canCreate: resource)
        case .update:
            return try await request(req, canUpdate: resource)
        case .save:
            return try await request(req, canSave: resource)
        case .delete:
            return try await request(req, canDelete: resource)
        }
    }
    
    open func assertRequest(_ req: Request, isAuthorizedTo action: AuthorizedAction, _ resources: [Resource]) async throws {
        guard try await request(req, isAuthorizedTo: action, resources) else {
            throw Abort(.unauthorized)
        }
    }
    open func request(_ req: Request, isAuthorizedTo action: AuthorizedAction, _ resources: [Resource]) async throws -> Bool {
        var authorized: Bool = true
        var authorizedInjected: Bool = true
        
        if let accessHandler = config.accessControl.resources[action] {
            authorizedInjected = try await accessHandler(req, resources)
        }
        
        switch action {
        case .read:
            authorized = try await request(req, canRead: resources)
        case .create:
            authorized = try await request(req, canCreate: resources)
        case .update:
            authorized = try await request(req, canUpdate: resources)
        case .save:
            authorized = try await request(req, canSave: resources)
        case .delete:
            authorized = try await request(req, canDelete: resources)
        }
        return authorized && authorizedInjected
    }
    
    open func request(_ req: Request, canRead resource: Resource) async throws -> Bool {
        return true
    }
    
    open func request(_ req: Request, canCreate resource: Resource) async throws -> Bool {
        return true
    }
    
    open func request(_ req: Request, canUpdate resource: Resource) async throws -> Bool {
        return true
    }
    
    open func request(_ req: Request, canSave resource: Resource) async throws -> Bool {
        return true
    }
    
    open func request(_ req: Request, canDelete resource: Resource) async throws -> Bool {
        return true
    }
    
    //Batch Actions
    open func request(_ req: Request, canSearch resources: [Resource]) async throws -> Bool {
        return true
    }
    
    open func request(_ req: Request, canRead resources: [Resource]) async throws -> Bool {
        return true
    }
    
    open func request(_ req: Request, canCreate resources: [Resource]) async throws -> Bool {
        return true
    }
    
    open func request(_ req: Request, canUpdate resources: [Resource]) async throws -> Bool {
        return true
    }
    
    open func request(_ req: Request, canSave resources: [Resource]) async throws -> Bool {
        return true
    }
    
    open func request(_ req: Request, canDelete resources: [Resource]) async throws -> Bool {
        return true
    }
    
    
    //MARK: End Access Control
    
    
    //MARK: Abstact methods
    
    //MARK: Abstact conversions
    open func convert(_ create: Create) throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    @discardableResult
    open func apply(_ update: Update, to resource: Resource) throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func read(_ resource: Resource) throws -> Read {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    //MARK: Abstract actions
    open func readModel(id: Resource.ResolvedParameter, request: Request) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func readAllModels(request: Request) async throws -> [Resource] {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func create(resource: Resource, request: Request) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func update(resource: Resource, request: Request) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    
    open func delete(resource: Resource, request: Request, force: Bool = false) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func save(resource: Resource, request: Request) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func create(resources: [Resource], request: Request) async throws -> [Resource] {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func update(resources: [Resource], request: Request) async throws -> [Resource] {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func delete(resources: [Resource], request: Request, force: Bool = false) async throws -> [Resource] {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    open func save(resources: [Resource], request: Request) async throws -> [Resource] {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    //MARK: Other
    
    open func update(resource: Resource,
                     with updateModel: Update,
                     request: Request) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    //MARK: End abstact methods
}
