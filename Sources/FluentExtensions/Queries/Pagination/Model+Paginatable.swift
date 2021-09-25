//
//  Model+Paginatable.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//

//extension Model where Self: Paginatable & Content {
//
//    /// Returns a paginated response on `.all()` entities
//    /// using page number from the request data
//    public static func paginate(
//        for request: Request,
//        pageKey: String = Pagination.Defaults.pageKey,
//        perPageKey: String = Pagination.Defaults.perPageKey,
//        _ sorts: [DatabaseQuery.Sort] = Self.defaultPageSorts
//    ) throws -> Future<Page<Self>> {
//
//        return try Self.query(on: request). page(for: req, pageKey: pageKey, perPageKey: perPageKey, sorts: sorts)
//    }
//
//}
