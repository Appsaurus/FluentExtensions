////
////  Controller.swift
////  App
////
////  Created by Brian Strobach on 1/21/21.
////

import RuntimeExtensions
import CollectionConcurrencyKit

/// A base controller class that provides RESTful API endpoints for a resource type.
///
/// The `Controller` class implements common CRUD operations and search functionality
/// for a specific resource type. It handles request authorization, route registration,
/// and provides extension points for customizing behavior.
///
/// ## Type Parameters
/// - Parameter Resource: The model type representing the resource being controlled
/// - Parameter Create: The model type used for resource creation requests
/// - Parameter Read: The model type returned in responses
/// - Parameter Update: The model type used for resource update requests
/// - Parameter SearchResult: The model type returned for search results
open class Controller<Resource: ResourceModel,
                      Create: CreateModel,
                      Read: ReadModel,
                      Update: UpdateModel,
                      SearchResult: SearchResultModel>: RouteCollection {
    
    /// Configuration for the controller's behavior and routing
    open var config: Config
    
    /// Creates a new controller instance with the specified configuration
    /// - Parameter config: The configuration to use for this controller
    public init(config: Config = Config()) {
        self.config = config
    }
    
    /// Creates a new controller instance with a configuration modifier
    /// - Parameter modifier: A closure that modifies the default configuration
    public convenience init(_ modifier: (Config) -> ()) {
        self.init()
        modifier(self.config)
    }
    
    // MARK: - Route Registration
    
    /// Registers all routes for this controller at the specified base path
    /// - Parameter routes: The routes builder to register routes with
    /// - Throws: An error if route registration fails
    open func boot(routes: RoutesBuilder) throws {
        let router = routes.grouped(config.baseRoute.pathComponents)
        try registerRoutes(routes: router)
    }
    
    /// Registers routes with the given route builder
    /// - Parameter routes: The routes builder to register routes with
    /// - Throws: An error if route registration fails
    open func registerRoutes(routes: RoutesBuilder) throws {
        try registerCRUDRoutes(routes: routes)
    }
    
    /// Registers CRUD routes based on the supported actions in configuration
    /// - Parameter routes: The routes builder to register routes with
    /// - Throws: An error if route registration fails
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
    
    // MARK: - Route Handlers
    
    /// Searches for resources matching the specified criteria
    /// - Parameter req: The incoming request
    /// - Returns: A search result containing matching resources
    /// - Throws: An error if the search operation fails
    open func search(on req: Request) async throws -> SearchResult {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    /// Retrieves a single resource by ID
    /// - Parameter req: The incoming request containing the resource ID
    /// - Returns: The requested resource
    /// - Throws: An error if the resource cannot be found or access is denied
    open func read(on req: Request) async throws -> Read {
        let resourceID = try req.parameters.next(Resource.self)
        let model = try await readModel(parameter: resourceID, on: req)
        try await assertRequest(req, isAuthorizedTo: .read, model)
        return try read(model)
    }
    
    /// Retrieves all resources
    /// - Parameter req: The incoming request
    /// - Returns: An array of all resources
    /// - Throws: An error if the operation fails or access is denied
    open func readAll(on req: Request) async throws -> [Read] {
        let models = try await readAllModels(on: req)
        try await assertRequest(req, isAuthorizedTo: .read, models)
        return try models.map(read)
    }
    
    // MARK: - Create Operations
    
    /// Creates a new resource
    /// - Parameters:
    ///   - req: The incoming request containing the resource data
    /// - Returns: The newly created resource
    /// - Throws: An error if creation fails or access is denied
    open func create(on req: Request) async throws -> Read {
        let model = try req.content.decode(Create.self)
        let resource = try convert(model)
        try await assertRequest(req, isAuthorizedTo: .create, resource)
        return try await self.create(createModel: model, on: req)
    }
    
    /// Creates multiple resources in a batch operation
    /// - Parameter req: The incoming request containing the resource data
    /// - Returns: An array of newly created resources
    /// - Throws: An error if creation fails or access is denied
    open func createBatch(on req: Request) async throws -> [Read] {
        let models = try req.content.decode([Create].self)
        let resources = try models.map(convert)
        try await assertRequest(req, isAuthorizedTo: .create, resources)
        return try await self.create(createModels: models, on: req)
    }
    
    /// Creates a single resource from a create model
    /// - Parameters:
    ///   - createModel: The model containing creation data
    ///   - req: The incoming request
    /// - Returns: The newly created resource
    /// - Throws: An error if creation fails or access is denied
    open func create(createModel: Create, on req: Request) async throws -> Read {
        var resource = try convert(createModel)
        try await assertRequest(req, isAuthorizedTo: .create, resource)
        resource = try await create(resource: resource, on: req)
        return try read(resource)
    }
    
    /// Creates multiple resources from create models
    /// - Parameters:
    ///   - createModels: An array of models containing creation data
    ///   - req: The incoming request
    /// - Returns: An array of newly created resources
    /// - Throws: An error if creation fails or access is denied
    open func create(createModels: [Create], on req: Request) async throws -> [Read] {
        let resources = try createModels.map(convert)
        try await assertRequest(req, isAuthorizedTo: .create, resources)
        return try await create(resources: resources, on: req).map(read)
    }
    
    // MARK: - Update Operations
    
    /// Updates a resource
    /// - Parameter req: The incoming request containing update data
    /// - Returns: The updated resource
    /// - Throws: An error if the update fails or access is denied
    open func update(on req: Request) async throws -> Read {
        let updateModel = try req.content.decode(Update.self)
        return try await update(updateModel: updateModel, on: req)
    }
    
    /// Updates multiple resources in a batch operation
    /// - Parameter req: The incoming request containing update data
    /// - Returns: An array of updated resources
    /// - Throws: An error if the update fails or access is denied
    open func updateBatch(on req: Request) async throws -> [Read] {
        let updateModels = try req.content.decode([Update].self)
        return try await self.update(updateModels: updateModels, on: req)
    }
    
    /// Updates a resource with the specified update model
    /// - Parameters:
    ///   - updateModel: The model containing update data
    ///   - req: The incoming request
    /// - Returns: The updated resource
    /// - Throws: An error if the update fails or access is denied
    open func update(updateModel: Update, on req: Request) async throws -> Read {
        let resourceID = try req.parameters.next(Resource.self)
        let resource = try await readModel(parameter: resourceID, on: req)
        try await assertRequest(req, isAuthorizedTo: .update, resource)
        let updatedResource = try await update(resource: resource,
                                               with: updateModel,
                                               on: req)
        return try read(updatedResource)
    }
    
    /// Updates multiple resources with update models
    /// - Parameters:
    ///   - updateModels: An array of models containing update data
    ///   - req: The incoming request
    /// - Returns: An array of updated resources
    /// - Throws: An error if the update fails or access is denied
    open func update(updateModels: [Update], on req: Request) async throws -> [Read] {
        return try await updateModels.asyncMap({try await self.update(updateModel: $0, on: req)})
    }
    
    // MARK: - Save Operations
    
    /// Saves a resource (creates or updates)
    /// - Parameter req: The incoming request containing the resource data
    /// - Returns: The saved resource
    /// - Throws: An error if the save operation fails or access is denied
    open func save(on req: Request) async throws -> Read {
        let saveModel = try req.content.decode(Create.self)
        return try await save(saveModel: saveModel, on: req)
    }
    
    /// Saves multiple resources in a batch operation
    /// - Parameter req: The incoming request containing the resources data
    /// - Returns: An array of saved resources
    /// - Throws: An error if the save operation fails or access is denied
    open func saveBatch(on req: Request) async throws -> [Read] {
        let saveModels = try req.content.decode([Create].self)
        return try await saveModels.asyncMap({try await self.save(saveModel: $0, on: req)})
    }
    
    /// Saves a resource using the specified save model
    /// - Parameters:
    ///   - saveModel: The model containing the resource data
    ///   - req: The incoming request
    /// - Returns: The saved resource
    /// - Throws: An error if the save operation fails or access is denied
    open func save(saveModel: Create, on req: Request) async throws -> Read {
        let saveResource = try convert(saveModel)
        try await assertRequest(req, isAuthorizedTo: .save, saveResource)
        let savedResource = try await save(resource: saveResource, on: req)
        return try read(savedResource)
    }
    
    /// Saves multiple resources using save models
    /// - Parameters:
    ///   - saveModels: An array of models containing the resource data
    ///   - req: The incoming request
    /// - Returns: An array of saved resources
    /// - Throws: An error if the save operation fails or access is denied
    open func save(saveModels: [Create], on req: Request) async throws -> [Read] {
        return try await saveModels.asyncMap({try await self.save(saveModel: $0, on: req)})
    }
    
    // MARK: - Delete
    
    /// Deletes a resource
    /// - Parameter req: The incoming request containing the resource ID
    /// - Returns: The deleted resource
    /// - Throws: An error if the deletion fails or access is denied
    open func delete(on req: Request) async throws -> Read {
        let resourceID = try req.parameters.next(Resource.self)
        let resource = try await self.readModel(parameter: resourceID, on: req)
        try await assertRequest(req, isAuthorizedTo: .delete, resource)
        let forceDelete = (try? req.query.get(Bool.self, at: "force")) ?? config.forceDelete
        let deletedModel = try await self.delete(resource: resource, on: req, force: forceDelete)
        return try read(deletedModel)
    }
    
    // MARK: - Access Control
    
    /// Asserts that the request is authorized to perform the specified action
    /// - Parameters:
    ///   - req: The incoming request
    ///   - action: The action to check authorization for
    ///   - resource: The resource being accessed
    /// - Throws: An error if the request is not authorized
    open func assertRequest(_ req: Request, isAuthorizedTo action: AuthorizedAction, _ resource: Resource) async throws {
        guard try await request(req, isAuthorizedTo: action, resource) else {
            throw Abort(.unauthorized)
        }
    }
    
    /// Checks if the request is authorized to perform the specified action
    /// - Parameters:
    ///   - req: The incoming request
    ///   - action: The action to check authorization for
    ///   - resource: The resource being accessed
    /// - Returns: A boolean indicating whether the request is authorized
    /// - Throws: An error if the authorization check fails
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
    
    /// Asserts that the request is authorized to perform the specified action
    /// - Parameters:
    ///   - req: The incoming request
    ///   - action: The action to check authorization for
    ///   - resources: The resources being accessed
    /// - Throws: An error if the request is not authorized
    open func assertRequest(_ req: Request, isAuthorizedTo action: AuthorizedAction, _ resources: [Resource]) async throws {
        guard try await request(req, isAuthorizedTo: action, resources) else {
            throw Abort(.unauthorized)
        }
    }
    
    /// Checks if the request is authorized to perform the specified action
    /// - Parameters:
    ///   - req: The incoming request
    ///   - action: The action to check authorization for
    ///   - resources: The resources being accessed
    /// - Returns: A boolean indicating whether the request is authorized
    /// - Throws: An error if the authorization check fails
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
    
    /// Checks if the request can read the specified resource
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resource: The resource being accessed
    /// - Returns: A boolean indicating whether the request can read the resource
    /// - Throws: An error if the check fails
    open func request(_ req: Request, canRead resource: Resource) async throws -> Bool {
        return true
    }
    
    /// Validates the creation of a resource
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resource: The resource being created
    /// - Throws: An error if the creation is invalid
    open func validateCreate(req: Request, for resource: Resource) async throws {}
    
    /// Checks if the request can create the specified resource
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resource: The resource being created
    /// - Returns: A boolean indicating whether the request can create the resource
    /// - Throws: An error if the check fails
    open func request(_ req: Request, canCreate resource: Resource) async throws -> Bool {
        try await validateCreate(req: req, for: resource)
        return true
    }
    
    /// Validates the update of a resource
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resource: The resource being updated
    /// - Throws: An error if the update is invalid
    open func validateUpdate(req: Request, for resource: Resource) async throws {}
    
    /// Checks if the request can update the specified resource
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resource: The resource being updated
    /// - Returns: A boolean indicating whether the request can update the resource
    /// - Throws: An error if the check fails
    open func request(_ req: Request, canUpdate resource: Resource) async throws -> Bool {
        try await validateUpdate(req: req, for: resource)
        return true
    }
    
    /// Validates the saving of a resource
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resource: The resource being saved
    /// - Throws: An error if the save is invalid
    open func validateSave(req: Request, for resource: Resource) async throws {}
    
    /// Checks if the request can save the specified resource
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resource: The resource being saved
    /// - Returns: A boolean indicating whether the request can save the resource
    /// - Throws: An error if the check fails
    open func request(_ req: Request, canSave resource: Resource) async throws -> Bool {
        try await validateSave(req: req, for: resource)
        return true
    }
    
    /// Checks if the request can delete the specified resource
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resource: The resource being deleted
    /// - Returns: A boolean indicating whether the request can delete the resource
    /// - Throws: An error if the check fails
    open func request(_ req: Request, canDelete resource: Resource) async throws -> Bool {
        return true
    }
    
    // MARK: - Batch Actions
    
    /// Checks if the request can search for the specified resources
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resources: The resources being searched
    /// - Returns: A boolean indicating whether the request can search for the resources
    /// - Throws: An error if the check fails
    open func request(_ req: Request, canSearch resources: [Resource]) async throws -> Bool {
        return true
    }
    
    /// Checks if the request can read the specified resources
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resources: The resources being read
    /// - Returns: A boolean indicating whether the request can read the resources
    /// - Throws: An error if the check fails
    open func request(_ req: Request, canRead resources: [Resource]) async throws -> Bool {
        return true
    }
    
    /// Checks if the request can create the specified resources
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resources: The resources being created
    /// - Returns: A boolean indicating whether the request can create the resources
    /// - Throws: An error if the check fails
    open func request(_ req: Request, canCreate resources: [Resource]) async throws -> Bool {
        return true
    }
    
    /// Checks if the request can update the specified resources
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resources: The resources being updated
    /// - Returns: A boolean indicating whether the request can update the resources
    /// - Throws: An error if the check fails
    open func request(_ req: Request, canUpdate resources: [Resource]) async throws -> Bool {
        return true
    }
    
    /// Checks if the request can save the specified resources
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resources: The resources being saved
    /// - Returns: A boolean indicating whether the request can save the resources
    /// - Throws: An error if the check fails
    open func request(_ req: Request, canSave resources: [Resource]) async throws -> Bool {
        return true
    }
    
    /// Checks if the request can delete the specified resources
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resources: The resources being deleted
    /// - Returns: A boolean indicating whether the request can delete the resources
    /// - Throws: An error if the check fails
    open func request(_ req: Request, canDelete resources: [Resource]) async throws -> Bool {
        return true
    }
    
    // MARK: - Abstract Methods
    
    /// Converts a create model to a resource
    /// - Parameter create: The create model to convert
    /// - Returns: The converted resource
    /// - Throws: An error if the conversion fails
    open func convert(_ create: Create) throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    /// Reads a resource
    /// - Parameter resource: The resource to read
    /// - Returns: The read resource
    /// - Throws: An error if the read operation fails
    open func read(_ resource: Resource) throws -> Read {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    /// Reads a model from a parameter
    /// - Parameters:
    ///   - parameter: The parameter to read from
    ///   - req: The incoming request
    /// - Returns: The read model
    /// - Throws: An error if the read operation fails
    open func readModel(parameter: Resource.ResolvedParameter, on req: Request) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    /// Reads all models
    /// - Parameter req: The incoming request
    /// - Returns: An array of read models
    /// - Throws: An error if the read operation fails
    open func readAllModels(on req: Request) async throws -> [Resource] {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    /// Creates a resource
    /// - Parameters:
    ///   - resource: The resource to create
    ///   - req: The incoming request
    /// - Returns: The created resource
    /// - Throws: An error if the creation fails
    open func create(resource: Resource, on req: Request) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    /// Updates a resource
    /// - Parameters:
    ///   - resource: The resource to update
    ///   - req: The incoming request
    /// - Returns: The updated resource
    /// - Throws: An error if the update fails
    open func update(resource: Resource, on req: Request) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    /// Deletes a resource
    /// - Parameters:
    ///   - resource: The resource to delete
    ///   - req: The incoming request
    ///   - force: A boolean indicating whether to force the deletion
    /// - Returns: The deleted resource
    /// - Throws: An error if the deletion fails
    open func delete(resource: Resource, on req: Request, force: Bool = false) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    /// Saves a resource
    /// - Parameters:
    ///   - resource: The resource to save
    ///   - req: The incoming request
    /// - Returns: The saved resource
    /// - Throws: An error if the save operation fails
    open func save(resource: Resource, on req: Request) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    /// Creates multiple resources
    /// - Parameters:
    ///   - resources: The resources to create
    ///   - req: The incoming request
    /// - Returns: An array of created resources
    /// - Throws: An error if the creation fails
    open func create(resources: [Resource], on req: Request) async throws -> [Resource] {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    /// Updates multiple resources
    /// - Parameters:
    ///   - resources: The resources to update
    ///   - req: The incoming request
    /// - Returns: An array of updated resources
    /// - Throws: An error if the update fails
    open func update(resources: [Resource], on req: Request) async throws -> [Resource] {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    /// Deletes multiple resources
    /// - Parameters:
    ///   - resources: The resources to delete
    ///   - req: The incoming request
    ///   - force: A boolean indicating whether to force the deletion
    /// - Returns: An array of deleted resources
    /// - Throws: An error if the deletion fails
    open func delete(resources: [Resource], on req: Request, force: Bool = false) async throws -> [Resource] {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    /// Saves multiple resources
    /// - Parameters:
    ///   - resources: The resources to save
    ///   - req: The incoming request
    /// - Returns: An array of saved resources
    /// - Throws: An error if the save operation fails
    open func save(resources: [Resource], on req: Request) async throws -> [Resource] {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    /// Updates a resource with the specified update model
    /// - Parameters:
    ///   - resource: The resource to update
    ///   - updateModel: The update model to apply
    ///   - req: The incoming request
    /// - Returns: The updated resource
    /// - Throws: An error if the update fails
    open func update(resource: Resource,
                     with updateModel: Update,
                     on req: Request) async throws -> Resource {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
}
