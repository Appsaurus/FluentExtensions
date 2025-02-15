//
//  FluentAdminController.swift
//
//
//  Created by Brian Strobach on 8/16/24.
//


open class FluentAdminController<Model: FluentResourceModel>: FluentController<Model,Model,Model,Model>
where Model.ResolvedParameter == Model.IDValue,
      Model: Content {

    //MARK: Abstract Implementations
    open override func resolveID(for parameter: Model.ResolvedParameter, on req: Request) async throws -> Model.IDValue {
        return parameter
    }
    
    
    open override func update(resource: Model,
                              with updateModel: Model,
                                                   on req: Request) async throws -> Model {
        
        if (updateModel.id == nil) {
            updateModel.id = try resource.requireID()
        }
        if (updateModel.id != resource.id) {
            throw Abort(.badRequest)
        }
        return updateModel
    }
    
    open override func convert(_ create: Model) throws -> Model {
        return create
    }
    
    @discardableResult
    open override func apply(_ update: Model, to model: Model) throws -> Model {
        return update
    }
    
    open override func read(_ model: Model) throws -> Model {
        var mModel = model
        try mModel.beforeEncode()
        return mModel
    }
    
    //    MARK: Children Routes
    public func childCRUDRoute<C: FluentResourceModel, CC, CR, CU>(_ routes: RoutesBuilder,
                                                                   pathSlug: String = "children",
                                                                   queryParamKey: String = "ids",
                                                                   childForeignKeyPath: ChildrenPropertyKeyPath<Model, C>,
                                                                   childController: FluentController<C, CC, CR, CU> = .init()) {
        let path = Model.childCRUDPath(childForeignKeyPath, slug: pathSlug)
        
        //Replace attached children with new children
        routes.put(at: path) { (request, resource: Model, body: [C]) async throws -> [CR] in
            return try await resource.replaceChildren(with: body,
                                                      through: childForeignKeyPath,
                                                      in: request.db)
            .map(childController.read)
        }
        
        let searchPath = path + ["search"]
        routes.get(searchPath.pathComponents) { request in
            return try await childController.search(on: request)
        }
        
        //Get currently attached children
        routes.get(path, params: Model.self) { (request, model) async throws -> [CR] in
            let _ = try model.requireID()
            let children = model[keyPath: childForeignKeyPath]
            return try await children.query(on: request.db)
                .all()
                .map(childController.read)
        }
        
        let attachPath = path + ["attach"]
        routes.put(attachPath, params: Model.self) { (request, model) async throws -> HTTPResponseStatus in
            let _ = try model.requireID()
            let childEntities = try request.content.decode([C].self)
            let childRelationship = model[keyPath: childForeignKeyPath]
            try await childRelationship.attach(childEntities, in: request.db)
            return .ok
        }
        
        let detachPath = path + ["detach"]
        routes.put(detachPath, params: Model.self) { (request, model) async throws -> HTTPResponseStatus in
            let _ = try model.requireID()
            let childEntities = try request.content.decode([C].self)
            let childRelationship = model[keyPath: childForeignKeyPath]
            try await childRelationship.detach(childEntities, in: request.db)
            return .ok
        }
    }
    
    
    //Siblings
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
    public func pivotCRUDRoutes<S, P, PC, PR, PU>(_ routes: RoutesBuilder,
                                                  relationshipName: String = Model.crudPathName + "_" + S.crudPathName,
                                                  through siblingKeyPath: SiblingPropertyKeyPath<Model, S, P>,
                                                  pivotController: FluentController<P, PC, PR, PU> = .init())
    where S: FluentResourceModel,
          P: FluentResourceModel {
              let pivotPath = Model.pivotCRUDPath(relationshipName: relationshipName)
              
              routes.get(pivotPath) { (request: Request, model: Model) async throws -> [PR] in
                  return try await model[keyPath: siblingKeyPath]
                      .$pivots
                      .query(on: request.db).all()
                      .map(pivotController.read)
              }
              
              //Replace
              routes.put([P].self, at: pivotPath) { (request, model: Model, pivotEntities) async throws -> [PR] in
                  let database = request.db
                  let pivotProperty = model[keyPath: siblingKeyPath].$pivots
                  return try await pivotProperty.replace(with: pivotEntities, in: database)
                      .map(pivotController.read)
              }
              
              let attachPath = pivotPath + ["attach"]
              routes.put(attachPath, params: Model.self) { (request, model) async throws -> [PR] in
                  let _ = try model.requireID()
                  let pivotEntities = try request.content.decode([P].self)
                  try await pivotEntities.upsert(in: request.db)
                  let siblingRelationship = model[keyPath: siblingKeyPath]
                  return try await siblingRelationship
                      .$pivots
                      .attach(pivotEntities, in: request.db)
                      .map(pivotController.read)
              }
              
              let detachPath = pivotPath + ["detach"]
              routes.put(detachPath, params: Model.self) { (request, model) async throws -> [PR] in
                  //TODO: Confirm exist and already attached.
                  let pivotEntities = try request.content.decode([P].self)
                  let siblingRelationship = model[keyPath: siblingKeyPath]
                  return try await siblingRelationship
                      .$pivots
                      .detach(pivotEntities, in: request.db)
                      .map(pivotController.read)
              }
              
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
                return try await siblingRelationship
                    .query(on: request.db)
                    .all()
                    .map(siblingController.read)
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
