import Fluent

public extension Model {
    /// Updates the value at a specific key path for all models matching the given filters
    /// - Parameters:
    ///   - keyPath: The key path to the property to update
    ///   - value: The new value to set
    ///   - filters: The filters to determine which models to update
    ///   - database: The database connection to perform the update on
    /// - Returns: Array of updated model instances
    /// - Throws: Any database errors that occur during the update
    static func updateValue<Property: QueryableProperty>(
        at keyPath: KeyPath<Self, Property>,
        to value: Property.Value,
        where filters: ModelValueFilter<Self>...,
        in database: Database
    ) async throws -> [Self] {
        let models = try await findAll(where: filters, limit: nil, on: database)
        return try await models.updateValue(at: keyPath, to: value, in: database)
    }
}

public extension Collection where Element: Model {
    /// Updates a specific property value for all models in the collection
    /// - Parameters:
    ///   - keyPath: The key path to the property to update
    ///   - value: The new value to set
    ///   - database: The database connection to perform the update on
    /// - Returns: Array of updated model instances
    /// - Throws: Any database errors that occur during the update
    func updateValue<Property: QueryableProperty>(
        at keyPath: KeyPath<Element, Property>,
        to value: Property.Value,
        in database: Database
    ) async throws -> [Element] {
        let mutatedValues: [Element] = self.map { model in
            let mutableModel = model
            mutableModel[keyPath: keyPath].value = value
            return mutableModel
        }

        return try await mutatedValues.update(in: database, transaction: true)
    }
}

public extension Sequence where Element: Model {
    /// Updates a specific property value for all models in the sequence
    /// - Parameters:
    ///   - keyPath: The key path to the property to update
    ///   - value: The new value to set
    ///   - database: The database connection to perform the update on
    /// - Returns: Array of updated model instances
    /// - Throws: Any database errors that occur during the update
    func updateValue<Property: QueryableProperty>(
        at keyPath: KeyPath<Element, Property>,
        to value: Property.Value,
        in database: Database
    ) async throws -> [Element] {
        let mutatedValues = self.map { model in
            let mutableModel = model
            mutableModel[keyPath: keyPath].value = value
            return mutableModel
        }

        return try await mutatedValues.update(in: database, transaction: true)
    }
}
