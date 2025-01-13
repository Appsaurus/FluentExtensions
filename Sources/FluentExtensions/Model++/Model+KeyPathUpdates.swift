import Fluent

public extension Model {
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
