//
//  FluentController.swift
//
//
//  Created by Brian Strobach on 8/16/24.
//

import VaporExtensions

public typealias FluentResourceModel = Fluent.Model & ResourceModel & Paginatable

open class FluentController<Model: FluentResourceModel,
                            Create: CreateModel,
                            Read: ReadModel,
                            Update: UpdateModel>: Controller<Model, Create, Read, Update, Page<Read>> {
    
    open var defaultSort: DatabaseQuery.Sort? = .sort(.path([Model.idFieldKey],
                                                       schema: Model.schemaOrAlias), .ascending)
    
    open var parameterFilterConfig = QueryParameterFilter.Builder<Model>.Config()
    
    public override init(config: Config = Config()) {
        let modifiedConfig = config
        // Only modify baseRoute if it's empty
        if modifiedConfig.baseRoute.isEmpty {
            modifiedConfig.baseRoute = [Model.crudPathName]
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
    
    //MARK: Abstract Implementations
    
    open override func readAllModels(request: Request) async throws -> [Model] {
        return try await Model.query(on: request.db).all()
    }
    
    open override func create(resource: Model, request: Request) async throws -> Model {
        try await create(model: resource, in: request.db)
    }
    
    open override func update(resource: Model, request: Request) async throws -> Model {
        try await update(model: resource, in: request.db)
    }
    
    open override func save(resource: Model, request: Request) async throws -> Model {
        switch config.saveMethod {
        case .save:
            try await save(model: resource, in: request.db)
        case .upsert:
            try await upsert(model: resource, in: request.db)
        }
    }
    
    open override func delete(resource: Model, request: Request, force: Bool = false) async throws -> Model {
        try await delete(model: resource, in: request.db)
    }
    
    open override func create(resources: [Model], request: Request) async throws -> [Model] {
        try await request.db.performBatch(action: self.create, on: resources)
    }
    
    open override func update(resources: [Model], request: Request) async throws -> [Model] {
        try await request.db.performBatch(action: self.update, on: resources)
    }
    
    open override func save(resources: [Model], request: Request) async throws -> [Model] {
        switch config.saveMethod {
        case .save:
            try await request.db.performBatch(action: self.save, on: resources)
        case .upsert:
            try await request.db.performBatch(action: self.upsert, on: resources)
        }
        

    }
    
    open override func delete(resources: [Model], request: Request, force: Bool = false) async throws -> [Model] {
        try await resources.delete(force: force, on: request.db)
        return resources
    }
    
    //MARK: End Abstract Implementations
    
    //MARK: Database-Level Implementations
    
    open func create(model: Model, in db: Database) async throws -> Model {
        try await model.create(in: db)
    }
    
    open func update(model: Model, in db: Database) async throws -> Model {
        try await model.update(in: db)
    }
    
    open func save(model: Model, in db: Database) async throws -> Model {
        try await model.save(in: db)
    }
    
    open func upsert(model: Model, in db: Database) async throws -> Model {
        try await model.upsert(in: db)
    }
    
    open func delete(model: Model, in db: Database, force: Bool = false) async throws -> Model {
        try await model.delete(from: db, force: force)
    }
    
    open func isJoinedRequest(_ request: Request) -> Bool {
        if let joinedParam = try? request.query.get(Bool.self, at: "joined") {
            return joinedParam
        }
        return false
    }
    open func join(query: QueryBuilder<Model>) -> QueryBuilder<Model> {
        return query
    }
    
    public func buildSearchQuery(request: Request) throws -> QueryBuilder<Model> {
        return try buildSearchQuery(joined: isJoinedRequest(request), request: request)
    }
    
    open func buildSearchQuery(joined: Bool, request: Request) throws -> QueryBuilder<Model> {
        var query = Model.query(on: request)
        if isJoinedRequest(request) {
            query = join(query: query)
        }
        return try applyQueryConstraints(query: query, on: request)
    }
    
    open func applyQueryConstraints(query: QueryBuilder<Model>,
                                   on request: Request) throws -> QueryBuilder<Model> {
        var query = query
        query = try filterSearch(query: query, on: request)
        query = try sortSearch(query: query, on: request)
        return query
    }

    
    open func filterSearch(query: QueryBuilder<Model>,
                           on request: Request) throws -> QueryBuilder<Model> {
        var query = query
        if let queryString = request.query[String.self, at: "query"] {
            let queryString = queryString.trimmingCharacters(in: .punctuationCharacters)
            query = try filter(queryBuilder: query, for: queryString)
        }
        
        query = try query.filterWithQueryParameter(in: request, builder: .init(query, config: self.parameterFilterConfig))

        return query
    }
    
    open func sortSearch(query: QueryBuilder<Model>, on request: Request) throws -> QueryBuilder<Model> {
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
    
    @discardableResult
    open func filter(queryBuilder: QueryBuilder<Model>,
                     for searchQuery: String) throws -> QueryBuilder<Model> {
        return queryBuilder
    }
    
    //MARK: End Database-Level Implementations
}
