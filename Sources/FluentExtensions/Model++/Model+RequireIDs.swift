//
//  Model+RequireIDs.swift
//
//
//  Created by Brian Strobach on 10/14/21.
//

import Fluent

public extension Collection where Element: Model {
    /// Retrieves all IDs from the collection's models, throwing an error if any ID is missing
    /// - Returns: Array of model IDs
    /// - Throws: An error if any model in the collection doesn't have an ID
    func requireIDs() throws -> [Element.IDValue] {
        return try compactMap { try $0.requireID() }
    }

    /// Retrieves all available IDs from the collection's models
    /// - Note: Unlike `requireIDs()`, this property silently filters out models without IDs
    var ids: [Element.IDValue] {
        return compactMap { $0.id }
    }
}
