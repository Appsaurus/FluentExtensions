//
//  TestParentModel.swift
//  FluentTestModels
//
//  Created by Brian Strobach on 12/1/17.
//

import FluentExtensions
private extension FieldKey {
    static var name: Self { "name" }

}

public final class TestParentModel: TestModel, @unchecked Sendable {

    @ID(key: .id)
    public var id: UUID?

    @Field(key: .name)
    public var name: String

    @Children(for: \.$parent)
    public var children: [TestChildModel]

    public init() {}

    public init(id: UUID? = nil,
                name: String) {
        self.id = id
        self.name = name
    }
}

//MARK: Reflection-based migration
public final class TestParentModelReflectionMigration: AutoMigration<TestParentModel>, @unchecked Sendable  {}

//MARK: Manual migration
public final class TestParentModelMigration: AsyncMigration {
    public func prepare(on database: Database) async throws {
        try await database.schema(TestParentModel.schema)
            .id()
            .field(.name, .string, .required)
            .create()

    }

    public func revert(on database: Database) async throws {
        return try await database.schema(TestParentModel.schema).delete()
    }
}
