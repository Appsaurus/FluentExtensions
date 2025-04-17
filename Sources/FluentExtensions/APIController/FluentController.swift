//
//  FluentController.swift
//
//
//  Created by Brian Strobach on 8/16/24.
//

import VaporExtensions

/// A base controller class that provides CRUD operations for Fluent models.
///
/// The `FluentController` class serves as a foundation for building RESTful API endpoints
/// that interact with database models through Vapor and Fluent.
///
/// - Parameters:
///   - Model: The database model type that conforms to `FluentResourceModel`
///   - Create: The type used for creating new model instances
///   - Read: The type used for reading model instances
///   - Update: The type used for updating model instances
public typealias FluentResourceModel = Fluent.Model & ResourceModel & Paginatable

open class FluentController<Model: FluentResourceModel,
                            Create: CreateModel,
                            Read: ReadModel,
                            Update: UpdateModel>: Controller<Model, Create, Read, Update, Page<Read>> {
    
    /// Default sorting configuration for database queries.
    open var defaultSort: DatabaseQuery.Sort? = .sort(.path([Model.idFieldKey],
                                                       schema: Model.schemaOrAlias), .ascending)
    
    /// Configuration for handling query parameter filters.
    open var parameterFilterConfig = QueryParameterFilter.Builder<Model>.Config()
    
    /// Creates a new instance of the controller with the specified configuration.
    /// - Parameter config: The configuration object for the controller.
    public override init(config: Config = Config()) {
        let modifiedConfig = config
        // Only modify baseRoute if it's empty
        if modifiedConfig.baseRoute.isEmpty {
            modifiedConfig.baseRoute = [Model.crudPathName]
        }
        super.init(config: modifiedConfig)
    }
    
    // MARK: - Route Handlers
    
    /// Handles search requests with pagination support.
    /// - Parameter req: The incoming request
    /// - Returns: A page of read models
    /// - Throws: Any errors that occur during the search process
    open override func search(on req: Request) async throws -> Page<Read> {
        let query = try buildSearchQuery(on: req)
        return try await readPage(of: query, on: req)
    }
    
    // MARK: - Resource ID Resolution
    
    /// Requires and retrieves a resource ID from the request.
    /// - Parameter req: The incoming request
    /// - Returns: The resolved resource ID
    /// - Throws: `Abort(.badRequest)` if the ID cannot be resolved
    open func requireResourceID(on req: Request) async throws -> Model.IDValue {
        guard let id = try await resolveResourceID(on: req) else {
            throw Abort(.badRequest)
        }
        return id
    }
    
    /// Attempts to resolve a resource ID from the request parameters.
    /// - Parameter req: The incoming request
    /// - Returns: The resolved resource ID, if available
    open func resolveResourceID(on req: Request) async throws -> Model.IDValue? {
        if let parameterID = try? req.parameters.next(Model.self) {
            return try await resolveResourceID(for: parameterID, on: req)
        }
        return nil
    }
    
    /// Resolves a resource ID from a parameter value.
    /// - Parameters:
    ///   - parameter: The resolved parameter value
    ///   - req: The incoming request
    /// - Returns: The resolved resource ID
    /// - Throws: `Abort(.notFound)` by default
    open func resolveResourceID(for parameter: Model.ResolvedParameter, on req: Request) async throws -> Model.IDValue {
        assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        throw Abort(.notFound)
    }
    
    // MARK: - Model Preparation
    
    /// Prepares a model instance before creation.
    /// - Parameters:
    ///   - model: The model to prepare
    ///   - req: The incoming request
    /// - Returns: The prepared model
    @discardableResult
    open func prepareModelForCreating(model: Model, on req: Request) async throws -> Model {
        return model
    }
    
    /// Prepares a model instance before saving.
    /// - Parameters:
    ///   - model: The model to prepare
    ///   - req: The incoming request
    /// - Returns: The prepared model
    @discardableResult
    open func prepareModelForSaving(model: Model, on req: Request) async throws -> Model {
        try await prepareModelForCreating(model: model, on: req)
        try await prepareModelForUpdating(model: model, on: req)
        return model
    }
    
    /// Prepares a model instance before updating.
    /// - Parameters:
    ///   - model: The model to prepare
    ///   - req: The incoming request
    /// - Returns: The prepared model
    @discardableResult
    open func prepareModelForUpdating(model: Model, on req: Request) async throws -> Model {
        if let parameterResourceID = try? req.parameters.next(Model.self) {
            let parameterResource = try await readModel(parameter: parameterResourceID, on: req)
            if model.id == nil {
                model.id = try parameterResource.requireID()
            }
        }
        return model
    }
    
    // MARK: - Validation
    
    /// Validates a model before creation.
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resource: The model to validate
    open override func validateCreate(req: Request, for resource: Model) async throws {
        let parameterResourceID = try await resolveResourceID(on: req)
        guard parameterResourceID == nil else {
            throw Abort(.badRequest)
        }
        try await super.validateCreate(req: req, for: resource)
    }
    
    /// Validates a model before saving.
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resource: The model to validate
    open override func validateSave(req: Request, for resource: Model) async throws {
        if let parameterResourceID = try await resolveResourceID(on: req) {
            guard parameterResourceID == resource.id else {
                throw Abort(.badRequest)
            }
        }
        try await super.validateSave(req: req, for: resource)
    }
    
    /// Validates a model before updating.
    /// - Parameters:
    ///   - req: The incoming request
    ///   - resource: The model to validate
    open override func validateUpdate(req: Request, for resource: Model) async throws {
        let parameterResourceID = try await requireResourceID(on: req)
        let resourceID = try resource.requireID()
        guard resourceID == parameterResourceID else {
            throw Abort(.badRequest)
        }
        try await super.validateUpdate(req: req, for: resource)
    }
    
    // MARK: - Database Operations
    
    /// Reads a model instance from the database using a parameter value.
    open override func readModel(parameter: Model.ResolvedParameter, on req: Request) async throws -> Model {
        let resolvedID = try await resolveResourceID(for: parameter, on: req)
        return try await readModel(id: resolvedID, on: req)
    }
    
    /// Reads all model instances from the database.
    open override func readAllModels(on req: Request) async throws -> [Model] {
        return try await buildSearchQuery(on: req).all()
    }
    
    /// Creates a new model instance in the database.
    open override func create(resource: Model, on req: Request) async throws -> Model {
        try await prepareModelForCreating(model: resource, on: req)
        return try await create(model: resource, in: req.db)
    }
    
    /// Updates an existing model instance in the database.
    open override func update(resource: Model, on req: Request) async throws -> Model {
        try await prepareModelForUpdating(model: resource, on: req)
        return try await update(model: resource, in: req.db)
    }
    
    /// Determines if a request can save a model instance.
    open override func request(_ req: Request, canSave resource: Model) async throws -> Bool {
        guard try await super.request(req, canSave: resource) else {
            return false
        }
        try await validateSave(req: req, for: resource)
        return true
    }
    
    /// Saves a model instance to the database.
    open override func save(resource: Model, on req: Request) async throws -> Model {
        try await prepareModelForSaving(model: resource, on: req)
        switch config.saveMethod {
        case .save:
            return try await save(model: resource, in: req.db)
        case .upsert:
            return try await upsert(model: resource, in: req.db)
        }
    }
    
    /// Deletes a model instance from the database.
    open override func delete(resource: Model, on req: Request, force: Bool = false) async throws -> Model {
        try await delete(model: resource, in: req.db)
    }
    
    /// Creates multiple model instances in the database.
    open override func create(resources: [Model], on req: Request) async throws -> [Model] {
        try await req.db.performBatch(action: self.create, on: resources)
    }
    
    /// Updates multiple model instances in the database.
    open override func update(resources: [Model], on req: Request) async throws -> [Model] {
        try await req.db.performBatch(action: self.update, on: resources)
    }
    
    /// Saves multiple model instances to the database.
    open override func save(resources: [Model], on req: Request) async throws -> [Model] {
        switch config.saveMethod {
        case .save:
            return try await req.db.performBatch(action: self.save, on: resources)
        case .upsert:
            return try await req.db.performBatch(action: self.upsert, on: resources)
        }
    }
    
    /// Deletes multiple model instances from the database.
    open override func delete(resources: [Model], on req: Request, force: Bool = false) async throws -> [Model] {
        try await resources.delete(force: force, on: req.db)
        return resources
    }
    
    // MARK: - Database-Level Operations
    
    /// Creates a single model instance in the database.
    open func create(model: Model, in db: Database) async throws -> Model {
        try await model.create(in: db)
    }
    
    /// Updates a single model instance in the database.
    open func update(model: Model, in db: Database) async throws -> Model {
        try await model.update(in: db)
    }
    
    /// Saves a single model instance to the database.
    open func save(model: Model, in db: Database) async throws -> Model {
        try await model.save(in: db)
    }
    
    /// Upserts a single model instance in the database.
    open func upsert(model: Model, in db: Database) async throws -> Model {
        try await model.upsert(in: db)
    }
    
    /// Deletes a single model instance from the database.
    open func delete(model: Model, in db: Database, force: Bool = false) async throws -> Model {
        try await model.delete(from: db, force: force)
    }
    
    // MARK: - Query Building
    
    /// Determines if a request includes joined relationships.
    open func isJoinedRequest(_ request: Request) -> Bool {
        if let joinedParam = try? request.query.get(Bool.self, at: "joined") {
            return joinedParam
        }
        return false
    }
    
    /// Adds join clauses to a query.
    open func join(query: QueryBuilder<Model>) -> QueryBuilder<Model> {
        return query
    }
    
    /// Configures a query with optional join support.
    open func configure(query: QueryBuilder<Model>, on request: Request, join: Bool? = nil) -> QueryBuilder<Model> {
        let shouldJoin = join != nil ? join : isJoinedRequest(request)
        
        guard shouldJoin == true else {
            return query
        }
        return self.join(query: query)
    }
    
    /// Builds a base query for the model.
    open func buildQuery(on request: Request, join: Bool? = nil) throws -> QueryBuilder<Model> {
        let query = Model.query(on: request)
        return configure(query: query, on: request, join: join)
    }
    
    /// Reads a model instance by ID with optional join support.
    open func readModel(id: Model.IDValue, on req: Request, join: Bool? = nil) async throws -> Model {
        try await buildQuery(on: req, join: join)
            .filter(\._$id == id)
            .first()
            .unwrapped(or: Abort(.notFound))
    }
    
    /// Builds a query for searching with optional join support.
    open func buildSearchQuery(on req: Request, join: Bool? = nil) throws -> QueryBuilder<Model> {
        let query = try buildQuery(on: req, join: join)
        return try applyQueryConstraints(query: query, on: req)
    }
    
    /// Applies constraints to a query based on the request.
    open func applyQueryConstraints(query: QueryBuilder<Model>,
                                   on req: Request) throws -> QueryBuilder<Model> {
        var query = query
        query = try filterSearch(query: query, on: req)
        query = try sortSearch(query: query, on: req)
        return query
    }
    
    /// Applies filters to a search query based on request parameters.
    open func filterSearch(query: QueryBuilder<Model>,
                           on req: Request) throws -> QueryBuilder<Model> {
        var query = query
        if let queryString = req.query[String.self, at: "query"] {
            let queryString = queryString.trimmingCharacters(in: .punctuationCharacters)
            query = try filter(queryBuilder: query, for: queryString)
        }
        
        query = try query.filterWithQueryParameter(in: req, builder: .init(query, config: self.parameterFilterConfig))
        
        return query
    }
    
    /// Applies sorting to a search query based on request parameters.
    open func sortSearch(query: QueryBuilder<Model>, on req: Request) throws -> QueryBuilder<Model> {
        var sorts = try query.sorts(convertingKeysWith: { key in
            guard key.contains(".") else { return key }
            let split = key.split(separator: ".")
            var key: String = String(split[0])
            for keyPart in split[1...split.count - 1] {
                if keyPart.lowercased() == "id" {
                    key += keyPart.uppercased()
                } else {
                    key += keyPart.capitalized
                }
            }
            return key
        }, on: req)
        if sorts.count == 0, let defaultSort = self.defaultSort {
            sorts.append(defaultSort)
        }
        return query.sort(sorts)
    }
    
    /// Applies custom filtering to a query builder.
    @discardableResult
    open func filter(queryBuilder: QueryBuilder<Model>,
                     for searchQuery: String) throws -> QueryBuilder<Model> {
        return queryBuilder
    }
    
    /// Executes a read query with optional join support.
    open func executeRead(query: QueryBuilder<Model>, on req: Request, join: Bool? = nil) async throws -> [Read] {
        let query = configure(query: query, on: req, join: join)
        return try await readResults(of: query, on: req)
    }
    
    /// Executes a paginated read query with optional join support.
    open func executeReadPage(query: QueryBuilder<Model>, on req: Request, join: Bool? = nil) async throws -> Page<Read> {
        let query = configure(query: query, on: req, join: join)
        return try await readPage(of: query, on: req)
    }
    
    /// Reads and transforms query results into the read model type.
    open func readResults(of query: QueryBuilder<Model>, on req: Request) async throws -> [Read] {
        try await query
            .deduplicateJoinsToSameTable()
            .all()
            .map(read)
    }
    
    /// Reads and transforms paginated query results into the read model type.
    open func readPage(of query: QueryBuilder<Model>, on req: Request) async throws -> Page<Read> {
        try await query
            .deduplicateJoinsToSameTable()
            .paginate(for: req).transformDatum(with: read)
    }
}
