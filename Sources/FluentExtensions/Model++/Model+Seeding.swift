import FluentKit

/// A closure type that creates a new instance of a model
public typealias ModelInitializer<M: Model> = () -> M

public extension Model where Self: Decodable {
    /// Creates a new model instance with an optional ID
    /// - Parameters:
    ///   - id: Optional ID to assign to the new instance
    ///   - database: The database connection to create the model in
    ///   - initializer: A closure that returns a new model instance
    /// - Returns: The created model instance
    /// - Throws: Any database errors that occur during creation
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

    /// Synchronously creates a new model instance
    /// - Parameters:
    ///   - id: Optional ID to assign to the new instance
    ///   - database: The database connection to create the model in
    ///   - initializer: A closure that returns a new model instance
    /// - Returns: The created model instance
    /// - Throws: Any database errors that occur during creation
    @discardableResult
    static func createSync(
        id: IDValue? = nil,
        in database: Database,
        _ initializer: ModelInitializer<Self>
    ) async throws -> Self {
        try await create(id: id, in: database, initializer)
    }

    /// Creates multiple model instances synchronously
    /// - Parameters:
    ///   - size: The number of instances to create
    ///   - database: The database connection to create the models in
    ///   - initializer: A closure that returns a new model instance
    /// - Returns: Array of created model instances
    /// - Throws: Any database errors that occur during creation
    @discardableResult
    static func createBatchSync(
        size: Int,
        in database: Database,
        _ initializer: @escaping ModelInitializer<Self>
    ) async throws -> [Self] {
        try await createBatch(size: size, in: database, initializer)
    }

    /// Creates multiple model instances concurrently
    /// - Parameters:
    ///   - size: The number of instances to create
    ///   - database: The database connection to create the models in
    ///   - initializer: A closure that returns a new model instance
    /// - Returns: Array of created model instances
    /// - Throws: Any database errors that occur during creation
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

    /// Finds an existing model by ID or creates a new one
    /// - Parameters:
    ///   - id: The ID to search for
    ///   - database: The database connection to use
    ///   - initializer: A closure that returns a new model instance if none exists
    /// - Returns: The found or created model instance
    /// - Throws: Any database errors that occur during the operation
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

    /// Finds or creates multiple models by their IDs
    /// - Parameters:
    ///   - ids: Array of IDs to search for
    ///   - database: The database connection to use
    ///   - initializer: A closure that returns a new model instance if none exists
    /// - Returns: Array of found or created model instances
    /// - Throws: Any database errors that occur during the operation
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

    /// Synchronously finds or creates a model by ID
    /// - Parameters:
    ///   - id: The ID to search for
    ///   - database: The database connection to use
    ///   - initializer: A closure that returns a new model instance if none exists
    /// - Returns: The found or created model instance
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    static func findOrCreateSync(
        id: IDValue,
        in database: Database,
        _ initializer: @escaping ModelInitializer<Self>
    ) async throws -> Self {
        try await findOrCreate(id: id, in: database, initializer)
    }

    /// Synchronously finds or creates multiple models by their IDs
    /// - Parameters:
    ///   - ids: Array of IDs to search for
    ///   - database: The database connection to use
    ///   - initializer: A closure that returns a new model instance if none exists
    /// - Returns: Array of found or created model instances
    /// - Throws: Any database errors that occur during the operation
    @discardableResult
    static func findOrCreateBatchSync(
        ids: [IDValue],
        in database: Database,
        _ initializer: @escaping ModelInitializer<Self>
    ) async throws -> [Self] {
        try await findOrCreateBatch(ids: ids, in: database, initializer)
    }
}
