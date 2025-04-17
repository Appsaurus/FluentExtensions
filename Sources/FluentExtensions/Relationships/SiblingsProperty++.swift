//
//  SiblingExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 5/30/18.
//

import Foundation
import FluentKit

/// An extension of `SiblingsProperty` providing convenient access to pivot type.
public extension SiblingsProperty {
    /// The type of the pivot model used in the sibling relationship.
    static var pivotType: Through.Type {
        return Through.self
    }

    /// The type of the pivot model used in the sibling relationship.
    var pivotType: Through.Type {
        return Through.self
    }
}

/// Left-side extension of `SiblingsProperty` providing methods for working with sibling relationships.
public extension SiblingsProperty {
    /// Checks if a model is included in the sibling relationship.
    ///
    /// - Parameters:
    ///     - model: The model to check for inclusion.
    ///     - database: The database to perform the check on.
    /// - Returns: A boolean indicating whether the model is included in the sibling relationship.
    func includes(_ model: Through, on database: Database) async throws -> Bool {
        try await self.$pivots.includes(model, in: database)
    }

    /// Retrieves all models in the sibling relationship.
    ///
    /// - Parameters:
    ///     - database: The database to perform the retrieval on.
    /// - Returns: An array of models in the sibling relationship.
    func all(on database: Database) async throws -> [To] {
        return try await query(on: database).all()
    }
}

/// Extension of `SiblingsProperty` providing operations for working with sibling relationships.
extension SiblingsProperty {
    // MARK: Operations

    /// Replaces the existing sibling relationship with a new one.
    ///
    /// - Parameters:
    ///     - tos: An array of models to replace the existing sibling relationship.
    ///     - database: The database to perform the replacement on.
    ///     - policy: The strategy to use when removing existing siblings. Defaults to `.detach`.
    ///     - edit: An optional closure to edit the pivot model before saving it. Defaults to an empty closure.
    /// - Throws: An error if the replacement operation fails.
    public func replace(
        with tos: [To],
        on database: Database,
        by policy: RemovalMethod = .detach,
        _ edit: @Sendable @escaping (Through) -> () = { _ in }
    ) async throws {
        return try await database.transaction { database in
            switch policy {
            case .delete(let force):
                /// Deletes the existing sibling relationship.
                try await self.query(on: database).delete(force: force)
            case .detach:
                /// Detaches the existing sibling relationship.
                try await self.detachAll(on: database)
            }
            /// Attaches the new sibling relationship.
            return try await self.attach(tos, on: database, edit)
        }
    }
}

/// An enumeration of removal methods for sibling relationships.
public enum RemovalMethod {
    /// Deletes the existing sibling relationship.
    case delete(force: Bool)
    /// Detaches the existing sibling relationship.
    case detach
}
