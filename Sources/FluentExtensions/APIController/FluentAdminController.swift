//
//  FluentAdminController.swift
//
//
//  Created by Brian Strobach on 8/16/24.
//

/// A controller that provides full CRUD functionality for a Fluent model where the create, read, and update models are the same type.
///
/// The `FluentAdminController` simplifies API development by providing a complete set of CRUD operations
/// where the model itself serves as the create, read, and update representation.
///
/// Example usage:
/// ```swift
/// final class UserController: FluentAdminController<User> {
///     // Custom implementations if needed
/// }
/// ```
open class FluentAdminController<Model: FluentResourceModel>: FluentController<Model,Model,Model,Model>
where Model.ResolvedParameter == Model.IDValue,
      Model: Content {
    
    // MARK: - Abstract Implementations
    
    /// Resolves the resource ID from the route parameter.
    /// - Parameters:
    ///   - parameter: The resolved parameter from the route.
    ///   - req: The incoming request.
    /// - Returns: The resolved ID value.
    open override func resolveResourceID(for parameter: Model.ResolvedParameter, on req: Request) async throws -> Model.IDValue {
        return parameter
    }
    
    /// Updates a resource with new data.
    /// - Parameters:
    ///   - resource: The existing resource to update.
    ///   - updateModel: The new data to update with.
    ///   - req: The incoming request.
    /// - Returns: The updated resource.
    open override func update(resource: Model,
                              with updateModel: Model,
                              on req: Request) async throws -> Model {
        return updateModel //Request must supply entire model as update
    }
    
    /// Converts a create model to a resource model.
    /// - Parameter create: The create model.
    /// - Returns: The resource model.
    open override func convert(_ create: Model) throws -> Model {
        return create
    }
    
    /// Prepares a model for reading.
    /// - Parameter model: The model to prepare for reading.
    /// - Returns: The prepared model.
    open override func read(_ model: Model) throws -> Model {
        var mModel = model
        try mModel.beforeEncode()
        return mModel
    }
    
    // MARK: - Children Routes
    
    /// Registers CRUD routes for child relationships.
    /// - Parameters:
    ///   - routes: The route builder to register routes with.
    ///   - pathSlug: The path component for the children routes.
    ///   - queryParamKey: The query parameter key for batch operations.
    ///   - childForeignKeyPath: The key path to the children relationship.
    ///   - childController: The controller to handle child operations.
    public func childCRUDRoute<C: FluentResourceModel, CC, CR, CU>(_ routes: RoutesBuilder,
                                                                   pathSlug: String = "children",
                                                                   queryParamKey: String = "ids",
                                                                   childForeignKeyPath: ChildrenPropertyKeyPath<Model, C>,
                                                                   childController: FluentController<C, CC, CR, CU> = .init()) {
        let path = Model.childCRUDPath(childForeignKeyPath, slug: pathSlug)
        
        // Replace route
        routes.put(at: path) { (request, resource: Model, body: [C]) async throws -> [CR] in
            return try await resource.replaceChildren(with: body,
                                                      through: childForeignKeyPath,
                                                      in: request.db)
            .map(childController.read)
        }
        
        // Search route
        let searchPath = path + ["search"]
        routes.get(searchPath.pathComponents) { request in
            return try await childController.search(on: request)
        }
        
        // Read route
        routes.get(path, params: Model.self) { (request, model) async throws -> [CR] in
            let _ = try model.requireID()
            let children = model[keyPath: childForeignKeyPath]
            let query = children.query(on: request.db)
            return try await childController.executeRead(query: query, on: request)
        }
        
        // Attach route
        let attachPath = path + ["attach"]
        routes.put(attachPath, params: Model.self) { (request, model) async throws -> HTTPResponseStatus in
            let _ = try model.requireID()
            let childEntities = try request.content.decode([C].self)
            let childRelationship = model[keyPath: childForeignKeyPath]
            try await childRelationship.attach(childEntities, in: request.db)
            return .ok
        }
        
        // Detach route
        let detachPath = path + ["detach"]
        routes.put(detachPath, params: Model.self) { (request, model) async throws -> HTTPResponseStatus in
            let _ = try model.requireID()
            let childEntities = try request.content.decode([C].self)
            let childRelationship = model[keyPath: childForeignKeyPath]
            try await childRelationship.detach(childEntities, in: request.db)
            return .ok
        }
    }
    
    // MARK: - Siblings Routes
    
    /// Registers CRUD routes for pivot relationships.
    /// - Parameters:
    ///   - routes: The route builder to register routes with.
    ///   - relationshipName: The name of the relationship for route paths.
    ///   - siblingKeyPath: The key path to the siblings relationship.
    public func pivotCRUDRoutes<S, P>(_ routes: RoutesBuilder,
                                      relationshipName: String = Model.crudPathName + "_" + S.crudPathName,
                                      through siblingKeyPath: SiblingPropertyKeyPath<Model, S, P>)
    where S: FluentResourceModel,
          P: FluentResourceModel,
          P.ResolvedParameter == P.IDValue,
          P: Content
    {
        self.pivotCRUDRoutes(routes,
                             relationshipName: relationshipName,
                             through: siblingKeyPath,
                             pivotController: FluentAdminController<P>())
    }

    /// Registers CRUD routes for pivot relationships with a custom pivot controller.
    /// - Parameters:
    ///   - routes: The route builder to register routes with.
    ///   - relationshipName: The name of the relationship for route paths.
    ///   - siblingKeyPath: The key path to the siblings relationship.
    ///   - pivotController: The controller to handle pivot operations.
    public func pivotCRUDRoutes<S, P, PC, PR, PU>(_ routes: RoutesBuilder,
                                                  relationshipName: String = Model.crudPathName + "_" + S.crudPathName,
                                                  through siblingKeyPath: SiblingPropertyKeyPath<Model, S, P>,
                                                  pivotController: FluentController<P, PC, PR, PU> = .init())
    where S: FluentResourceModel,
          P: FluentResourceModel {
        let pivotPath = Model.pivotCRUDPath(relationshipName: relationshipName)
              
        func readAllPivots(model: Model, on req: Request) async throws -> [PR] {
            let query = model[keyPath: siblingKeyPath]
                .$pivots
                .query(on: req.db)
            return try await pivotController.executeRead(query: query, on: req, join: true)
        }
        
        // Read route
        routes.get(pivotPath) { (request: Request, model: Model) async throws -> [PR] in
            return try await readAllPivots(model: model, on: request)
        }
              
        // Replace route
        routes.put([P].self, at: pivotPath) { (request, model: Model, pivotEntities) async throws -> [PR] in
            let database = request.db
            let pivotProperty = model[keyPath: siblingKeyPath].$pivots
            try await pivotProperty.replace(with: pivotEntities, in: database)
            return try await readAllPivots(model: model, on: request)
        }
              
        // Attach route
        let attachPath = pivotPath + ["attach"]
        routes.put(attachPath, params: Model.self) { (request, model) async throws -> [PR] in
            let _ = try model.requireID()
            let pivotEntities = try request.content.decode([P].self)
            try await pivotEntities.upsert(in: request.db)
            let siblingRelationship = model[keyPath: siblingKeyPath]
            try await siblingRelationship
                .$pivots
                .attach(pivotEntities, in: request.db)
            return try await readAllPivots(model: model, on: request)
        }
              
        // Detach route
        let detachPath = pivotPath + ["detach"]
        routes.put(detachPath, params: Model.self) { (request, model) async throws -> [PR] in
            let pivotEntities = try request.content.decode([P].self)
            let siblingRelationship = model[keyPath: siblingKeyPath]
            try await siblingRelationship
                .$pivots
                .detach(pivotEntities, in: request.db)
            return try await readAllPivots(model: model, on: request)
        }
              
        // Delete route
        routes.delete(detachPath, params: Model.self) { (request, model) async throws -> HTTPResponseStatus in
            let siblingRelationship = model[keyPath: siblingKeyPath]
            let pivots = try await siblingRelationship
                .$pivots
                .query(on: request.db)
                .filterWithQueryParameter(in: request)
                .all()
            try await pivots.delete(from: request.db)
            return .ok
        }
    }
    
    public func siblingCRUDRoutes<P, S, SC, SR, SU>(_ routes: RoutesBuilder,
                                                    relationshipName: String = Model.crudPathName + "_" + S.crudPathName,
                                                    through siblingKeyPath: SiblingPropertyKeyPath<Model, S, P>,
                                                    siblingController: FluentController<S, SC, SR, SU> = .init())
    where S: FluentResourceModel {
        
        let siblingPath = Model.siblingCRUDPath(relationshipName: relationshipName)
        
        routes.get(siblingPath, params: Model.self) { (request: Request, model: Model) async throws -> [SR] in
            return try await model[keyPath: siblingKeyPath].query(on: request.db).all().map(siblingController.read)
        }
        
        routes.put(siblingPath, params: Model.self) { (request, model) async throws -> [SR] in
            return try await request.db.transaction { database in
                let siblingEntities = try request.content.decode([S].self)
                let siblingRelationship = model[keyPath: siblingKeyPath]
                try await siblingRelationship.replace(with: siblingEntities, on: database)
                let query = siblingRelationship.query(on: request.db)
                return try await siblingController.executeRead(query: query, on: request)
            }
        }
        
        let attachPath = siblingPath + ["attach"]
        routes.put(attachPath, params: Model.self) { (request, model) async throws -> HTTPResponseStatus in
            let _ = try model.requireID()
            let siblingEntities = try request.content.decode([S].self)
            let siblingRelationship = model[keyPath: siblingKeyPath]
            try await siblingRelationship.attach(siblingEntities, on: request.db)
            return .ok
        }
        
        let detachPath = siblingPath + ["detach"]
        routes.put(detachPath, params: Model.self) { (request, model) async throws -> HTTPResponseStatus in
            let _ = try model.requireID()
            let siblingEntities = try request.content.decode([S].self)
            let siblingRelationship = model[keyPath: siblingKeyPath]
            try await siblingRelationship.detach(siblingEntities, on: request.db)
            return .ok
        }
    }
}


extension Collection where Element == FieldKey {
    var propertyName: String{
        return map({$0.description}).joined(separator: ".")
    }
    
    var codingKeys: [CodingKeyRepresentable] {
        return map({$0.description})
    }
}

extension Model where Self: Parameter {
    
    static func siblingCRUDPath(relationshipName: String) -> [PathComponentRepresentable] {
        return [pathComponent, "siblings", relationshipName]
    }
    
    static func pivotCRUDPath(relationshipName: String) -> [PathComponentRepresentable] {
        return [pathComponent, "pivots", relationshipName]
    }
    
    static func foreignKeyPropertyName<Child: Model>(for childKeyPath: ChildrenPropertyKeyPath<Self, Child>) -> String {
        let relationship = Self()[keyPath: childKeyPath]
        switch relationship.parentKey {
        case .optional(let optional):
            return Child()[keyPath: optional].keys.propertyName
        case .required(let required):
            return Child()[keyPath: required].keys.propertyName
        }
    }
    static func childCRUDPath<Child: Model>(_ childKeyPath: ChildrenPropertyKeyPath<Self, Child>,
                                            slug: String = "children") -> [PathComponentRepresentable] {
        return [pathComponent, slug, foreignKeyPropertyName(for: childKeyPath)]
    }
}
