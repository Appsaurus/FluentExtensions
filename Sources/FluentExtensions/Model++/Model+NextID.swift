//
//  Model+NextID.swift
//
//
//  Created by Brian Strobach on 9/2/21.
//

import Fluent
import CollectionConcurrencyKit

public extension Model where IDValue == Int {
    /// Generates the next available ID value for the model
    /// - Parameter database: The database connection to query
    /// - Returns: The next available ID value
    /// - Throws: Any database errors that occur during the query
    /// - Note: This method is only available for models with Integer IDs
    static func nextID(on database: Database) async throws -> IDValue {
        let value = try await query(on: database).sort(\._$id, .descending).first()
        return (value?.id ?? -1) + 1
    }
}
