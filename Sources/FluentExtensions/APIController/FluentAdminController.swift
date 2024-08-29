//
//  FluentAdminController.swift
//
//
//  Created by Brian Strobach on 8/16/24.
//


open class FluentAdminController<R: FluentResourceModel>: FluentController<R,R,R,R>
where R.ResolvedParameter == R.IDValue, R: Content {
    
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
    func childCRUDRoute<C: FluentResourceModel, CC, CR, CU>(_ routes: RoutesBuilder,
                                                          pathSlug: String,
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

//        func childSearchRoute<C: AdminControllableModel>(_ routes: RoutesBuilder,
//                                                         pathSlug: String,
//                                                         childForeignKeyPath: ChildrenPropertyKeyPath<CRUDModel, C>,
//                                                         childController: FluentAdminController<C>) {
//            let searchPath: [PathComponentRepresentable] = CRUDModel.childCRUDPath(childForeignKeyPath, slug: pathSlug) + ["search"]
//            routes.get(searchPath.pathComponents) { (request) -> Future<[C]> in
//                return try childController.search(request: request).map({$0.data})
//            }
//        }
//
//        //Siblings
//
//        func pivotCRUDRoutes<S, T, P>(_ routes: RoutesBuilder,
//                                      relationshipName: String = CRUDModel.crudPathName + "_" + S.crudPathName,
//                                      through siblingKeyPath: SiblingPropertyKeyPath<CRUDModel, S, T>,
//                                      withPublicModel: P.Type = P.self)
//        where S.IDValue: Hashable,
//              P: Content & ModelConvertible, P.ModelType == T,
//              T: RelatedModelQueryable {
//            //Pivot Entity based API
//
//            let pivotPath = CRUDModel.pivotCRUDPath(relationshipName: relationshipName)
//
//            routes.get(pivotPath, params: CRUDModel.self) { (request: Request, model: CRUDModel) -> Future<[P]> in
//                return model[keyPath: siblingKeyPath].$pivots.query(on: request.db).withAllRelationships.all().to(P.self)
//            }
//
//            routes.put(pivotPath, params: CRUDModel.self) { (request, model) -> Future<[P]> in
//                let pivotEntities = try request.content.decode([P].self).toModel()
//                return request.db.transaction { database in
//                    model[keyPath: siblingKeyPath].$pivots.replace(with: pivotEntities, on: database)
//                }.flatMap {
//                    return model[keyPath: siblingKeyPath].$pivots.query(on: request.db).withAllRelationships.all()
//                }.to(P.self)
//            }
//
//            let attachPath = pivotPath + ["attach"]
//            routes.put(attachPath, params: CRUDModel.self) { (request, model) -> Future<[P]> in
//                let _ = try model.requireID()
//                let pivotEntities = try request.content.decode([P].self).toModel()
//                return model[keyPath: siblingKeyPath].$pivots
//                    .attach(pivotEntities, on: request.db)
//                    .transform(to: pivotEntities)
//                    .to(P.self)
//            }
//    //        let detachPath = pivotPath + ["detach"]
//    //        routes.put(detachPath, params: CRUDModel.self) { (request, model) -> Future<APISuccessResponse> in
//    //            let _ = try model.requireID()
//    //            let pivotEntities = try request.content.decode([P].self).toModel()
//    //            return model[keyPath: siblingKeyPath].$pivots
//    //                .detach(pivotEntities, on: request.db)
//    //                .transform(to: pivotEntities).transform(to: HTTPResponseStatus.ok).transform(to: APISuccessResponse("Successfully removed siblings."))
//    //        }
//        }
//
//        func siblingCRUDRoutes<S, T, P>(_ routes: RoutesBuilder,
//                                      relationshipName: String = CRUDModel.crudPathName + "_" + S.crudPathName,
//                                      through siblingKeyPath: SiblingPropertyKeyPath<CRUDModel, S, T>,
//                                      withPublicModel: P.Type = P.self)
//        where S: Model & Content {
//
//            let siblingPath = CRUDModel.siblingCRUDPath(relationshipName: relationshipName)
//
//            routes.get(siblingPath, params: CRUDModel.self) { (request: Request, model: CRUDModel) -> Future<[S]> in
//                return model[keyPath: siblingKeyPath].query(on: request.db).all()
//            }
//
//        }
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
        return [pathComponent, slug, Child.crudPathName, foreignKeyPropertyName(for: childKeyPath)]
    }
}
