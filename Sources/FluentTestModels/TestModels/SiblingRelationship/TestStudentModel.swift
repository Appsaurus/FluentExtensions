//
//  TestStudentModel.swift
//  FluentTestModels
//
//  Created by Brian Strobach on 12/11/17.
//

import FluentExtensions

public final class TestStudentModel: Model, Content {

    @ID(key: .id)
    public var id: UUID?

    @Siblings(through: TestEnrollmentModel.self, from: \.$student, to: \.$class)
    public var classes: [TestClassModel]

    public init() {}
}


//MARK: Reflection-based migration
class TestStudentModelReflectionMigration: AutoMigration<TestStudentModel> {}

//MARK: Manual migration
public class TestStudentModelMigration: AsyncMigration {
    public func prepare(on database: Database) async throws {
        try await database.schema(TestStudentModel.schema)
            .id()
            .create()

    }

    public func revert(on database: Database) async throws {
        return try await database.schema(TestStudentModel.schema).delete()
    }
}
