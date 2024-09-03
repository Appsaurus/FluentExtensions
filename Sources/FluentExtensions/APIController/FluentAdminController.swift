//
//  FluentAdminController.swift
//
//
//  Created by Brian Strobach on 8/16/24.
//


open class FluentAdminController<R: FluentResourceModel>: FluentController<R,R,R,R> where R.ResolvedParameter == R.IDValue,
                                                                                          R: Content {
    
    open override func readModel(id: R.IDValue, in db: Database) async throws -> R {
        return try await R.find(id, on: db).unwrapped(or: Abort(.notFound))
    }
    
    open override func update(model: R,
                              with updateModel: R,
                              in db: Database) async throws -> R {
        if (updateModel.id == nil) {
            updateModel.id = try model.requireID()
        }
        if (updateModel.id != model.id) {
            throw Abort(.badRequest)
        }
        return updateModel
    }
    
    open override func convert(_ create: R) throws -> R {
        return create
    }
    
    @discardableResult
    open override func apply(_ update: R, to model: R) throws -> R {
        return update
    }
    
    open override func read(_ model: R) throws -> R {
        return model
    }
    
    
    //    MARK: Children Routes
    public func childCRUDRoute<C: FluentResourceModel, CC, CR, CU>(_ routes: RoutesBuilder,
                                                            pathSlug: String = "children",
                                                            queryParamKey: String = "ids",
                                                            childForeignKeyPath: ChildrenPropertyKeyPath<R, C>,
                                                            childController: FluentController<C, CC, CR, CU>) {
        let path = R.childCRUDPath(childForeignKeyPath, slug: pathSlug)
        
        //Replace attached children with new children
        routes.put(path, params: R.self, use: { (request, model) async throws -> [CR] in
            let childrenModel = try request.content.decode([C].self)
            return try await model.replaceChildren(with: childrenModel,
                                                   through: childForeignKeyPath,
                                                   in: request.db)
            .map(childController.read)
        })
        
        //Get currently attached children
        routes.get(path, params: R.self) { (request, model) async throws -> [CR] in
            let _ = try model.requireID()
            let children = model[keyPath: childForeignKeyPath]
            return try await children.query(on: request.db)
                .all()
                .map(childController.read)
        }
        
        let searchPath = path + ["search"]
        routes.get(searchPath.pathComponents) { request in
            return try await childController.search(request)
        }
    }
    
    
    //Siblings
    
    public func pivotCRUDRoutes<S, P, PC, PR, PU>(_ routes: RoutesBuilder,
                                           relationshipName: String = R.crudPathName + "_" + S.crudPathName,
                                           through siblingKeyPath: SiblingPropertyKeyPath<R, S, P>,
                                           pivotController: FluentController<P, PC, PR, PU> = .init()) where S: FluentResourceModel,
                                                                                                             P: FluentResourceModel {              
              let pivotPath = R.pivotCRUDPath(relationshipName: relationshipName)
              
              routes.get(pivotPath, params: R.self) { (request: Request, model: R) async throws -> [PR] in
                  return try await model[keyPath: siblingKeyPath]
                      .$pivots
                      .query(on: request.db).all()
                      .map(pivotController.read)
              }
              
              routes.put(pivotPath, params: R.self) { (request, model) async throws -> [PR] in
                  return try await request.db.transaction { database in
                      let pivotEntities = try request.content.decode([P].self)
                      let siblingRelationship = model[keyPath: siblingKeyPath].$pivots
                      try await siblingRelationship.replace(with: pivotEntities, in: database)
                      return try await siblingRelationship
                          .query(on: request.db)
                          .all()
                          .map(pivotController.read)
                  }
              }
              
              let attachPath = pivotPath + ["attach"]
              routes.put(attachPath, params: R.self) { (request, model) async throws -> [PR] in
                  let _ = try model.requireID()
                  let pivotEntities = try request.content.decode([P].self)
                  let siblingRelationship = model[keyPath: siblingKeyPath].$pivots
                  return try await siblingRelationship
                      .attach(pivotEntities, in: request.db)
                      .map(pivotController.read)
              }
              
              let detachPath = pivotPath + ["detach"]
              routes.put(detachPath, params: R.self) { (request, model) async throws -> [PR] in
                  let _ = try model.requireID()
                  let pivotEntities = try request.content.decode([P].self)
                  let siblingRelationship = model[keyPath: siblingKeyPath].$pivots
                  return try await siblingRelationship.detach(pivotEntities, in: request.db)
                      .map(pivotController.read)
              }
          }
    
    public func siblingCRUDRoutes<P, S, SC, SR, SU>(_ routes: RoutesBuilder,
                                 relationshipName: String = R.crudPathName + "_" + S.crudPathName,
                                 through siblingKeyPath: SiblingPropertyKeyPath<R, S, P>,
                                                    siblingController: FluentController<S, SC, SR, SU>)
    where S: FluentResourceModel {
        
        let siblingPath = R.siblingCRUDPath(relationshipName: relationshipName)
        
        routes.get(siblingPath, params: R.self) { (request: Request, model: R) async throws -> [SR] in
            return try await model[keyPath: siblingKeyPath].query(on: request.db).all().map(siblingController.read)
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

extension ChildrenProperty {
    
    @discardableResult
    func detach(_ children: [To], in database: Database) async throws -> [To] {
        
        switch self.parentKey {
        case .required(_):
            throw Abort(.badRequest, reason: "That parent child relationship is required.")
        case .optional(let keyPath):
            children.forEach { $0[keyPath: keyPath].$id.value = nil }
            return try await children.upsert(in: database)
        }
    }
}
