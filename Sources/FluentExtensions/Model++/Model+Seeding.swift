import FluentKit

public typealias ModelInitializer<M: Model> = () -> M

public extension Model where Self: Decodable {
    @discardableResult
    static func create(
        id: IDValue? = nil,
        in database: Database,
        _ initializer: ModelInitializer<Self>
    ) async throws -> Self {
        let model: Self = initializer()
        if let id = id {
            model.id = id
        }
        try await model.create(on: database)
        return model
    }

    @discardableResult
    static func createSync(
        id: IDValue? = nil,
        in database: Database,
        _ initializer: ModelInitializer<Self>
    ) async throws -> Self {
        try await create(id: id, in: database, initializer)
    }

    @discardableResult
    static func createBatchSync(
        size: Int,
        in database: Database,
        _ initializer: @escaping ModelInitializer<Self>
    ) async throws -> [Self] {
        try await createBatch(size: size, in: database, initializer)
    }

    @discardableResult
    static func createBatch(
        size: Int,
        in database: Database,
        _ initializer: @escaping ModelInitializer<Self>
    ) async throws -> [Self] {
        guard size > 0 else { return [] }
        
        return try await withThrowingTaskGroup(of: Self.self) { group in
            for _ in 1...size {
                group.addTask {
                    try await self.create(in: database, initializer)
                }
            }
            
            var models: [Self] = []
            for try await model in group {
                models.append(model)
            }
            return models
        }
    }

    @discardableResult
    static func findOrCreate(
        id: IDValue,
        in database: Database,
        _ initializer: @escaping ModelInitializer<Self>
    ) async throws -> Self {
        if let existingModel = try await find(id, on: database) {
            return existingModel
        }
        return try await create(id: id, in: database, initializer)
    }

    @discardableResult
    static func findOrCreateBatch(
        ids: [IDValue],
        in database: Database,
        _ initializer: @escaping ModelInitializer<Self>
    ) async throws -> [Self] {
        try await withThrowingTaskGroup(of: Self.self) { group in
            for id in ids {
                group.addTask {
                    try await self.findOrCreate(id: id, in: database, initializer)
                }
            }
            
            var models: [Self] = []
            for try await model in group {
                models.append(model)
            }
            return models
        }
    }

    @discardableResult
    static func findOrCreateSync(
        id: IDValue,
        in database: Database,
        _ initializer: @escaping ModelInitializer<Self>
    ) async throws -> Self {
        try await findOrCreate(id: id, in: database, initializer)
    }

    @discardableResult
    static func findOrCreateBatchSync(
        ids: [IDValue],
        in database: Database,
        _ initializer: @escaping ModelInitializer<Self>
    ) async throws -> [Self] {
        try await findOrCreateBatch(ids: ids, in: database, initializer)
    }
}
