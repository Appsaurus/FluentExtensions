//
//  Model+Reflection.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 7/2/18.
//

import Foundation
import Fluent
import Vapor
import RuntimeExtensions

public extension Model where Self: KVC {
    /// Updates the current model with key-values from another model instance
    /// - Parameters:
    ///   - model: The source model to copy values from
    ///   - database: The database connection to perform the update on
    /// - Returns: The updated model instance
    /// - Throws: Any database errors that occur during the update
    func updateWithKeyValues(of model: Self,
                           on database: Database) async throws -> Self {
        try await updateWithKeyValues(of: model).save(on: database)
        return model
    }
}
