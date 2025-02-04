//
//  FluentController.swift
//
//
//  Created by Brian Strobach on 8/16/24.
//

import VaporExtensions

public typealias FluentResourceModel = Fluent.Model & ResourceModel & Paginatable

open class FluentController<Resource: FluentResourceModel,
                            Create: CreateModel,
                            Read: ReadModel,
                            Update: UpdateModel>: Controller<Resource, Create, Read, Update, Page<Read>> {
    
    open var defaultSort: DatabaseQuery.Sort? = .sort(.path([Resource.idFieldKey],
                                                       schema: Resource.schemaOrAlias), .ascending)
    
    open var queryParameterFilterOverrides: QueryBuilderParameterFilterOverrides<Resource> = [:]
    
    public override init(config: Config = Config()) {
        var modifiedConfig = config
        // Only modify baseRoute if it's empty
        if modifiedConfig.baseRoute.isEmpty {
            modifiedConfig.baseRoute = [Resource.crudPathName]
        }
        super.init(config: modifiedConfig)
    }
    
    //MARK: Routes
    
    open override func search(_ req: Request) async throws -> Page<Read> {
        let query = try buildSearchQuery(request: req)
        let page = try await query.paginate(for: req)
        try await assertRequest(req, isAuthorizedTo: .read, page.items)
        return try page.transformDatum(with: read)
    }
    //MARK: End Routes
    
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
        try await models.upsert(in: db)
        //        try await db.performBatch(action: self.upsert, on: models)
    }
    
    //MARK: Other
    
    //    open override func update(model: Resource,
    //                              with updateModel: Update,
    //                              in db: Database) async throws -> Resource {
    //
    //    }
    
    //MARK: Search
    //    @discardableResult
    //    open func defaultSort() -> DatabaseQuery.Sort? {
    //        DatabaseQuery.Sort.sort(.path([Resource.idFieldKey], schema: Resource.schemaOrAlias), .ascending)
    //    }
    

    
    open func buildSearchQuery(request: Request) throws -> QueryBuilder<Resource> {
        let query = Resource.query(on: request)
        return try applyQueryConstraints(query: query, on: request)
    }
    
    open func applyQueryConstraints(query: QueryBuilder<Resource>,
                                   on request: Request) throws -> QueryBuilder<Resource> {
        var query = query
        query = try filterSearch(query: query, on: request)
        query = try sortSearch(query: query, on: request)
        return query
    }
    
    open func filterWithQueryParameters(query: QueryBuilder<Resource>,
                                        on request: Request,
                                        overrides: QueryBuilderParameterFilterOverrides<Resource>) throws -> QueryBuilder<Resource> {
        try query.filterWithQueryParameter(in: request, overrides: overrides)
    }
    
    open func filterSearch(query: QueryBuilder<Resource>,
                           on request: Request) throws -> QueryBuilder<Resource> {
        var query = query
        if let queryString = request.query[String.self, at: "query"] {
            let queryString = queryString.trimmingCharacters(in: .punctuationCharacters)
            query = try filter(queryBuilder: query, for: queryString)
        }
        
        query = try filterWithQueryParameters(query: query, on: request, overrides: self.queryParameterFilterOverrides)

        return query
    }
    
    open func sortSearch(query: QueryBuilder<Resource>, on request: Request) throws -> QueryBuilder<Resource> {
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
        }, on: request)
        if sorts.count == 0, let defaultSort = self.defaultSort {
            sorts.append(defaultSort)
        }
        return query.sort(sorts)
    }
    
    //    open func applyFilter(for property: PropertyInfo, to query: QueryBuilder<Resource>,
    //                          on request: Request) throws {
    //        try query.filter(property, on: request)
    //    }
    
    @discardableResult
    open func filter(queryBuilder: QueryBuilder<Resource>,
                     for searchQuery: String) throws -> QueryBuilder<Resource> {
        return queryBuilder
    }
    
    
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
