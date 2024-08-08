//
//  TestClassModel.swift
//  
//
//  Created by Brian Strobach on 8/31/21.
//

import FluentExtensions

public final class TestClassModel: Model, Content {

    @ID(key: .id)
    public var id: UUID?

    @Siblings(through: TestEnrollmentModel.self, from: \.$class, to: \.$student)
    public var students: [TestStudentModel]

    public init() {}
}

//MARK: Reflection-based migration
class TestClassModelReflectionMigration: AutoMigration<TestClassModel> {}

//MARK: Manual migration
public class TestClassModelMigration: AsyncMigration {
    public func prepare(on database: Database) async throws {
        try await database.schema(TestClassModel.schema)
            .id()
            .create()
    }

    public func revert(on database: Database) async throws {
        return try await database.schema(TestClassModel.schema).delete()
    }
}
