//
//  TestTestChildModel.swift
//  
//
//  Created by Brian Strobach on 8/31/21.
//

import FluentExtensions

private extension FieldKey {
    static var name: Self { "nameID" }
    static var parent: Self { "parentID" }
}
public final class TestChildModel: TestModel {

    @ID(key: .id)
    public var id: UUID?

    @Field(key: .name)
    public var name: String

    @Parent(key: .parent)
    public var parent: TestParentModel

    public init() {}

    public init(id: UUID? = nil,
                name: String,
                parent: TestParentModel) throws {
        self.id = id
        self.name = name
        self.$parent.id = try parent.requireID()
    }
}

//MARK: Reflection-based migration
class TestChildModelReflectionMigration: AutoMigration<TestChildModel> {
    override var fieldKeyMap: [String : FieldKey] {
        [ "name" : .name, "parent" : .parent]
    }
}

//MARK: Manual migration
public class TestChildModelMigration: AsyncMigration {
    public func prepare(on database: Database) async throws {
        try await database.schema(TestChildModel.schema)
            .id()
            .field(.name, .string, .required)
            .field(.parent, .uuid, .required)
            .foreignKey(.parent, references: TestParentModel.schema, .id)
            .create()

    }

    public func revert(on database: Database) async throws {
        return try await database.schema(TestChildModel.schema).delete()
    }
}
