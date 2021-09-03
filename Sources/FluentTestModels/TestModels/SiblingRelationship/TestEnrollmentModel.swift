//
//  TestTestEnrollmentModel.swift
//  
//
//  Created by Brian Strobach on 8/31/21.
//

import FluentExtensions

private extension FieldKey {
    static var student: Self { "student" }
    static var `class`: Self { "class" }
}

public final class TestEnrollmentModel: Model, Content {

    @ID(key: .id)
    public var id: UUID?

    @Parent(key: .`class`)
     var `class`: TestClassModel

    @Parent(key: .student)
     var student: TestStudentModel

    public init() { }
}

//MARK: Reflection-based migration
class TestEnrollmentModelReflectionMigration: AutoMigration<TestEnrollmentModel> {
    @discardableResult
    override func customize(schema: SchemaBuilder) -> SchemaBuilder {
        schema.unique(on: .student, .`class`)
    }
}

//MARK: Manual migration
public class TestEnrollmentModelMigration: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {

        database.schema(TestEnrollmentModel.schema)
            .id()
            .field(.student, .uuid, .required)
            .field(.`class`, .uuid, .required)
            .unique(on: .student, .`class`)
            .create()

    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(TestEnrollmentModel.schema).delete()
    }
}
