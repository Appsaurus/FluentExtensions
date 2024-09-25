import Vapor
import Fluent

public class PivotEntityDefaults {
    // Global default fields for fromID and toID, used across the system.
    public static var defaultFromIDField: String = "fromID"
    public static var defaultToIDField: String = "toID"
}
// MARK: - PivotEntity: A Generic Pivot Model
public final class PivotEntity<From, To>: FluentResourceModel
where From: Model, To: Model {

    // Generate schema name dynamically based on relationship
    public static func schema(for relationshipName: String) -> String {
        return "\(From.schema)_\(To.schema)_\(relationshipName)_pivot"
    }

    @ID(key: .id)
    public var id: UUID?

    @Parent(key: FieldKey(PivotEntityDefaults.defaultFromIDField))
    public var from: From

    @Parent(key: FieldKey(PivotEntityDefaults.defaultToIDField))
    public var to: To

    public init() { }

    public init(fromId: From.IDValue, toId: To.IDValue) {
        self.$from.id = fromId
        self.$to.id = toId
    }

    // Async method to create schema using default or custom field names
    public static func createSchema(
        for relationshipName: String,
        fromIDField: String = PivotEntityDefaults.defaultFromIDField,
        toIDField: String = PivotEntityDefaults.defaultToIDField,
        on database: Database
    ) async throws {
        try await database.schema(schema(for: relationshipName))
            .id()
            .field(FieldKey(fromIDField), .uuid, .required)
            .field(FieldKey(toIDField), .uuid, .required)
            .foreignKey(FieldKey(fromIDField), references: From.schema, .id)
            .foreignKey(FieldKey(toIDField), references: To.schema, .id)
            .create()
    }
    
    // Async method to drop schema using the relationship name
    public static func dropSchema(
        for relationshipName: String,
        on database: Database
    ) async throws {
        try await database.schema(schema(for: relationshipName)).delete()
    }
}

// MARK: - PivotMigration to Manage Migrations
struct PivotMigration<From: Model, To: Model>: AsyncMigration {

    let relationshipName: String
    let fromIDField: String
    let toIDField: String

    init(relationshipName: String, fromIDField: String = PivotEntityDefaults.defaultFromIDField, toIDField: String = PivotEntityDefaults.defaultToIDField) {
        self.relationshipName = relationshipName
        self.fromIDField = fromIDField
        self.toIDField = toIDField
    }

    // Async prepare migration
    func prepare(on database: Database) async throws {
        try await PivotEntity<From, To>.createSchema(
            for: relationshipName,
            fromIDField: fromIDField,
            toIDField: toIDField,
            on: database
        )
    }

    // Async revert migration
    func revert(on database: Database) async throws {
        try await PivotEntity<From, To>.dropSchema(
            for: relationshipName,
            on: database
        )
    }
}
