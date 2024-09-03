//
//  TestUserModel.swift
//  
//
//  Created by Brian Strobach on 8/13/21.
//

import FluentExtensions

private extension FieldKey {
    static var name: Self { "name" }
}

public final class TestUserModel: TestModel {

    @ID(key: .id)
    public var id: UUID?

    @Field(key: .name)
    public var name: String

    @SelfSiblingsProperty(through: TestFriendshipModel.self, from: \.$fromUser, to: \.$toUser)
    public var socialGraph: [TestUserModel]

    public init() {}

    public init(id: UUID? = nil,
                name: String) {
        self.id = id
        self.name = name
    }
}

//MARK: Reflection-based migration
class TestUserModelReflectionMigration: AutoMigration<TestUserModel> {}

//MARK: Manual migration
public class TestUserModelMigration: AsyncMigration {
    public func prepare(on database: Database) async throws {
        try await database.schema(TestUserModel.schema)
            .id()
            .field(.name, .string, .required)
            .create()
    }

    public func revert(on database: Database) async throws {
        return try await database.schema(TestUserModel.schema).delete()
    }
}
