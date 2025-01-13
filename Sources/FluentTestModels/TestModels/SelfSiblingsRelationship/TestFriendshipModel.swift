//
//  TestFriendshipModel.swift
//  
//
//  Created by Brian Strobach on 8/31/21.
//

import FluentExtensions

private extension FieldKey {
    static var fromUser: Self { "fromUser"}
    static var toUser: Self { "toUser"}
}

public final class TestFriendshipModel: TestModel, @unchecked Sendable {

    @ID(key: .id)
    public var id: UUID?

    @Parent(key: .fromUser)
    public var fromUser: TestUserModel

    @Parent(key: .toUser)
    public var toUser: TestUserModel

    public init() { }


//    init(id: UUID? = nil, users: (TestUserModel, TestUserModel)) throws {
//
//        let leftID = try users.0.requireID()
//        let rightID = try users.1.requireID()
//
//        guard leftID != rightID else {
//            throw Abort(.badRequest, reason: "A sibling cannot be related to itself.")
//        }
//
//        //Friendship is represented by single connection, so we sort to create avoid duplicates.
//        let ids = [leftID, rightID].sorted { leftUUID, rightUUID in
//            leftUUID.uuidString < rightUUID.uuidString
//        }
//        self.id = id
//        self.$fromUser.id = ids[0]
//        self.$toUser.id = ids[1]
//    }
}

//MARK: Reflection-based migration
public final class TestFriendshipModelReflectionMigration: AutoMigration<TestFriendshipModel>,
                                                           @unchecked Sendable  {
    public override func customize(schema: SchemaBuilder) -> SchemaBuilder {
        schema.unique(on: .toUser, .fromUser)
    }
}

//MARK: Manual migration
public final class TestFriendshipModelMigration: AsyncMigration {
    public func prepare(on database: Database) async throws {
        try await database.schema(TestFriendshipModel.schema)
            .id()
            .field(.toUser, .uuid, .required)
            .foreignKey(.toUser, references: TestUserModel.schema, .id)
            .field(.fromUser, .uuid, .required)
            .foreignKey(.fromUser, references: TestUserModel.schema, .id)
            .unique(on: .toUser, .fromUser)
            .create()
    }

    public func revert(on database: Database) async throws {
        return try await database.schema(TestFriendshipModel.schema).delete()
    }
}
