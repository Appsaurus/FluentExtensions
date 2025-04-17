import Vapor
import Fluent

/// Global configuration for pivot entity default field names
public class PivotEntityDefaults {
    /// Default field name for the "from" relationship ID
    public static var defaultFromIDField: String = "fromID"
    /// Default field name for the "to" relationship ID
    public static var defaultToIDField: String = "toID"
}

/// A generic pivot model for managing many-to-many relationships
public final class PivotEntity<From, To>: FluentResourceModel
where From: Model, To: Model {

    /// Generates a schema name for the pivot entity
    /// - Parameter relationshipName: The name of the relationship
    /// - Returns: A string representing the schema name
    public static func schema(for relationshipName: String) -> String {
        return "\(From.schema)_\(To.schema)_\(relationshipName)_pivot"
    }

    /// The unique identifier for the pivot entity
    @ID(key: .id)
    public var id: UUID?

    /// The relationship to the "from" model
    @Parent(key: FieldKey(PivotEntityDefaults.defaultFromIDField))
    public var from: From

    /// The relationship to the "to" model
    @Parent(key: FieldKey(PivotEntityDefaults.defaultToIDField))
    public var to: To

    /// Creates a new empty pivot entity
    public init() { }

    /// Creates a new pivot entity with specified IDs
    /// - Parameters:
    ///   - fromId: The ID of the "from" model
    ///   - toId: The ID of the "to" model
    public init(fromId: From.IDValue, toId: To.IDValue) {
        self.$from.id = fromId
        self.$to.id = toId
    }

    /// Creates the database schema for the pivot entity
    /// - Parameters:
    ///   - relationshipName: The name of the relationship
    ///   - fromIDField: The field name for the "from" relationship ID
    ///   - toIDField: The field name for the "to" relationship ID
    ///   - database: The database to create the schema in
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
    
    /// Drops the database schema for the pivot entity
    /// - Parameters:
    ///   - relationshipName: The name of the relationship
    ///   - database: The database to drop the schema from
    public static func dropSchema(
        for relationshipName: String,
        on database: Database
    ) async throws {
        try await database.schema(schema(for: relationshipName)).delete()
    }
}

/// A migration for managing pivot entity schema
struct PivotMigration<From: Model, To: Model>: AsyncMigration {

    let relationshipName: String
    let fromIDField: String
    let toIDField: String

    init(relationshipName: String, fromIDField: String = PivotEntityDefaults.defaultFromIDField, toIDField: String = PivotEntityDefaults.defaultToIDField) {
        self.relationshipName = relationshipName
        self.fromIDField = fromIDField
        self.toIDField = toIDField
    }

    /// Prepares the migration by creating the pivot entity schema
    /// - Parameter database: The database to prepare the migration in
    func prepare(on database: Database) async throws {
        try await PivotEntity<From, To>.createSchema(
            for: relationshipName,
            fromIDField: fromIDField,
            toIDField: toIDField,
            on: database
        )
    }

    /// Reverts the migration by dropping the pivot entity schema
    /// - Parameter database: The database to revert the migration in
    func revert(on database: Database) async throws {
        try await PivotEntity<From, To>.dropSchema(
            for: relationshipName,
            on: database
        )
    }
}
