//
//  Migratable.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/18/24.
//

import Foundation
import Vapor
import Fluent
import Runtime
import RuntimeExtensions

/// A protocol that provides automatic database migration capabilities for conforming types.
///
/// The `Migratable` protocol simplifies database schema management by providing a standardized way
/// to define migrations. When implemented alongside Fluent's `Model` protocol, it automatically
/// generates migrations based on the model's structure.
///
/// Example:
/// ```swift
/// struct User: Model, Migratable {
///     static let schema = "users"
///
///     @ID(key: .id)
///     var id: UUID?
///
///     @Field(key: "name")
///     var name: String
/// }
/// ```
public protocol Migratable {
    /// The migration instance responsible for managing database schema changes.
    static var migration: Migration { get }
}

public extension Migratable where Self: Model {
    /// Default implementation that provides automatic migration capabilities for Fluent models.
    ///
    /// This implementation creates an `AutoMigration` instance that handles schema creation and updates
    /// based on the model's properties and relationships.
    static var migration: Migration {
        return AutoMigration<Self>()
    }
}

public extension Migrations {
    /// Adds a single migratable model type to the migration configuration.
    ///
    /// - Parameters:
    ///   - model: The migratable model type to add.
    ///   - id: Optional database identifier to specify which database the migration should run against.
    func add(_ model: Migratable.Type, to id: DatabaseID? = nil) {
        add(model.migration)
    }

    /// Adds multiple migratable model types to the migration configuration.
    ///
    /// - Parameters:
    ///   - model: A variadic list of migratable model types to add.
    ///   - id: Optional database identifier to specify which database the migrations should run against.
    @inlinable
    func add(_ model: Migratable.Type..., to id: DatabaseID? = nil) {
        self.add(model, to: id)
    }

    /// Adds an array of migratable model types to the migration configuration.
    ///
    /// - Parameters:
    ///   - models: An array of migratable model types to add.
    ///   - id: Optional database identifier to specify which database the migrations should run against.
    func add(_ models: [Migratable.Type], to id: DatabaseID? = nil) {
        models.forEach { model in
            add(model, to: id)
        }
    }
}
