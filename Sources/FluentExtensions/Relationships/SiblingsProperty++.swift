//
//  SiblingExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 5/30/18.
//

import Foundation
import FluentKit

public extension SiblingsProperty{
	static var pivotType: Through.Type {
		return Through.self
	}

	var pivotType: Through.Type {
		return Through.self
	}
}

/// Left-side
public extension SiblingsProperty{

    /// Pure sugar wrapping isAttached() in order to match child API name
    func includes(_ model: Through, on database: Database) async throws -> Bool {
        try await self.$pivots.includes(model, in: database)
    }

    func all(on database: Database) async throws -> [To] {
        return try await query(on: database).all()
    }
}


extension SiblingsProperty {
    // MARK: Operations

    /// Attach an array model to this model through a pivot.
    ///
    /// - Parameters:
    ///     - tos: An array of models to replace all siblings through a sibling relationship
    ///     - database: The database to perform the attachment on.
    ///     - policy: The strategy to use when removing existing siblings
    ///     - edit: An optional closure to edit the pivot model before saving it.
    public func replace(
        with tos: [To],
        on database: Database,
        by policy: RemovalMethod = .detach,
        _ edit: @Sendable @escaping (Through) -> () = { _ in }
    ) async throws {
        return try await database.transaction { database in
            switch policy {
            case .delete(let force):
                try await self.query(on: database).delete(force: force)
            case .detach:
                try await self.detachAll(on: database)
            }
            return try await self.attach(tos, on: database, edit)
        }
        
    }
}

public enum RemovalMethod {
    case delete(force: Bool)
    case detach
}
