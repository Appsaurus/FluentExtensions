//
//  TestStudentModel.swift
//  FluentTestModels
//
//  Created by Brian Strobach on 12/11/17.
//

import FluentExtensions

private extension FieldKey {
    static var name: Self { "name" }
}

public final class TestStudentModel: TestModel, @unchecked Sendable {
    
    @ID(key: .id)
    public var id: UUID?
    
    @Field(key: .name)
    public var name: String

//    @Siblings()
//    public var classes: [TestClassModel]
    
    @Siblings(through: TestEnrollmentModel.self, from: \.$student, to: \.$class)
    public var classes: [TestClassModel]

    public init() {}
    
    public init(id: UUID? = nil, name: String, classes: [TestClassModel]? = nil) {
        self.id = id
        self.name = name
        if let classes {
            self.classes = classes
        }
    }
}


//MARK: Reflection-based migration
public final class TestStudentModelReflectionMigration: AutoMigration<TestStudentModel>, @unchecked Sendable {}

//MARK: Manual migration
public final class TestStudentModelMigration: AsyncMigration {
    public func prepare(on database: Database) async throws {
        try await database.schema(TestStudentModel.schema)
            .id()
            .field(.name, .string, .required)
            .create()

    }

    public func revert(on database: Database) async throws {
        return try await database.schema(TestStudentModel.schema).delete()
    }
}
