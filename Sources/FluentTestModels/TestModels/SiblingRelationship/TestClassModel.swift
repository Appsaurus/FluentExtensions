//
//  TestClassModel.swift
//  
//
//  Created by Brian Strobach on 8/31/21.
//

import FluentExtensions

public final class TestClassModel: TestModel, @unchecked Sendable {

    @ID(key: .id)
    public var id: UUID?

    @Siblings(through: TestEnrollmentModel.self, from: \.$class, to: \.$student)
    public var students: [TestStudentModel]

    public init() {}
    
    public init(id: UUID? = nil, students: [TestStudentModel]? = nil) {
        self.id = id
        if let students {
            self.students = students
        }        
    }
}

//MARK: Reflection-based migration
public final class TestClassModelReflectionMigration: AutoMigration<TestClassModel>, @unchecked Sendable {}

//MARK: Manual migration
public final class TestClassModelMigration: AsyncMigration {
    public func prepare(on database: Database) async throws {
        try await database.schema(TestClassModel.schema)
            .id()
            .create()
    }

    public func revert(on database: Database) async throws {
        return try await database.schema(TestClassModel.schema).delete()
    }
}
