import Vapor
import Fluent

public class PivotEntityDefaults {
    // Global default fields for fromID and toID, used across the system.
    public static var defaultFromIDField: String = "fromID"
    public static var defaultToIDField: String = "toID"
}
// MARK: - PivotEntity: A Generic Pivot Model
public final class PivotEntity<From, To>: Model
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

// MARK: - Pivot Property Wrapper
@propertyWrapper
public struct Pivot<From, To> where From: Model, To: Model {
    
    public var relationName: String
    public var pivots: [To]?
    public var fromIDField: String
    public var toIDField: String

    public init(_ relationName: String,
                fromIDField: String = PivotEntityDefaults.defaultFromIDField,
                toIDField: String = PivotEntityDefaults.defaultToIDField) {
        self.relationName = relationName
        self.fromIDField = fromIDField
        self.toIDField = toIDField
    }

    public var wrappedValue: [To] {
        get {
            guard let pivots = self.pivots else {
                fatalError("Pivot relation not eager loaded, use $ prefix to access.")
            }
            return pivots
        }
        set {
            self.pivots = newValue
        }
    }

    public var projectedValue: Pivot<From, To> {
        return self
    }

    // Async method to attach models through the pivot
    public func attach(
        _ tos: [To],
        on database: Database
    ) async throws {
        guard let fromID = self.fromID else {
            fatalError("Cannot attach to unsaved model.")
        }
        for to in tos {
            guard let toID = to.id else {
                fatalError("Cannot attach unsaved models.")
            }
            let pivot = PivotEntity<From, To>(fromId: fromID, toId: toID)
            try await pivot.create(on: database)
        }
    }

    // Query for the related models
    public func query(on database: Database) -> QueryBuilder<To> {
        guard let fromID = self.fromID else {
            fatalError("Cannot query pivot from unsaved model.")
        }

        return To.query(on: database)
            .join(PivotEntity<From, To>.self,
                  on: To.idPropertyKeyPath == \PivotEntity<From, To>.$to.$id)
            .filter(PivotEntity<From, To>.self, \PivotEntity<From, To>.$from.$id == fromID)
    }

    // Async method to detach models from the pivot
    public func detach(_ tos: [To], on database: Database) async throws {
        guard let fromID = self.fromID else {
            fatalError("Cannot detach from unsaved model.")
        }

        let toIDs = tos.compactMap { $0.id }
        try await PivotEntity<From, To>.query(on: database)
            .filter(\.$from.$id == fromID)
            .filter(\.$to.$id ~~ toIDs)
            .delete()
    }

    // Internal property to store the ID of the `From` model
    private var fromID: From.IDValue?
}

// MARK: - KeyPath Extension for Migration Derivation
//extension KeyPath where Root: Model, Value == Pivot<From, To> {
//    
//    var fromType: From.Type {
//        return From.self
//    }
//
//    var toType: To.Type {
//        return To.self
//    }
//
//    var relationshipName: String {
//        return "\(fromType.schema)_\(toType.schema)"
//    }
//
//    // Generate an AsyncMigration from KeyPath
//    func migration(
//        fromIDField: String = PivotEntityDefaults.defaultFromIDField,
//        toIDField: String = PivotEntityDefaults.defaultToIDField
//    ) -> AsyncMigration {
//        return PivotMigration<From, To>(
//            relationshipName: self.relationshipName,
//            fromIDField: fromIDField,
//            toIDField: toIDField
//        )
//    }
//}

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
