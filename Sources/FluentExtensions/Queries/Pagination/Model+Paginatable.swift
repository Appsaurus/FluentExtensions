//
//  Model+Paginatable.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//

import Fluent

/// Extension providing pagination capabilities to models that conform to Paginatable and Content
extension Model where Self: Paginatable & Content {
    /// Paginates all instances of the model with optional sorting
    /// - Parameters:
    ///   - req: The request containing pagination parameters
    ///   - pageKey: The query parameter key for the page number (defaults to Pagination.Defaults.pageKey)
    ///   - perPageKey: The query parameter key for items per page (defaults to Pagination.Defaults.perPageKey)
    ///   - sorts: Optional array of sort criteria to apply before pagination
    /// - Returns: A paginated response containing the requested items
    /// - Throws: Any errors encountered during the database query
    public static func paginate(
        for req: Request,
        pageKey: String = Pagination.Defaults.pageKey,
        perPageKey: String = Pagination.Defaults.perPageKey,
        _ sorts: [DatabaseQuery.Sort] = []
    ) async throws -> Fluent.Page<Self> {
        return try await Self.query(on: req)
            .sort(sorts)
            .paginate(for: req, pageKey: pageKey, perPageKey: perPageKey)
    }
}
