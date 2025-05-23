//
//  TestTestChildModel.swift
//  
//
//  Created by Brian Strobach on 8/31/21.
//

import FluentExtensions

private extension FieldKey {
    static var name: Self { "name" }
    static var parent: Self { "parentID" }
    static var optionalParent: Self { "optionalParentID" }
}
public final class TestChildModel: TestModel, @unchecked Sendable {
    
    @ID(key: .id)
    public var id: UUID?
    
    @Field(key: .name)
    public var name: String
    
    @Parent(key: .parent)
    public var parent: TestParentModel
    
    @OptionalParent(key: .optionalParent)
    public var optionalParent: TestParentModel?
    
    public init() {}
    
    public init(id: UUID? = nil,
                name: String,
                parentID: TestParentModel.IDValue? = nil,
                optionalParentID: TestParentModel.IDValue? = nil) {
        self.id = id
        self.name = name
        if let parentID {
            self.$parent.id = parentID
        }
        self.$optionalParent.id = optionalParentID
        
    }
}

//MARK: Reflection-based migration
final class TestChildModelReflectionMigration: AutoMigration<TestChildModel>, @unchecked Sendable {
    override var fieldKeyMap: [String : FieldKey] {
        [ 
            "name" : .name,
            "parent" : .parent,
            "optionalParent" : .optionalParent
        ]
    }
}

//MARK: Manual migration
public class TestChildModelMigration: AsyncMigration, @unchecked Sendable {
    public func prepare(on database: Database) async throws {
        try await database.schema(TestChildModel.schema)
            .id()
            .field(.name, .string, .required)
            .field(.parent, .uuid, .required)
            .foreignKey(.parent, references: TestParentModel.schema, .id)
            .field(.optionalParent, .uuid)
            .foreignKey(.parent, references: TestParentModel.schema, .id)
            .create()
        
    }
    
    public func revert(on database: Database) async throws {
        return try await database.schema(TestChildModel.schema).delete()
    }
}
