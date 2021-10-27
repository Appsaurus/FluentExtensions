//
//  Model+Paginatable.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//

import Fluent

extension Model where Self: Paginatable & Content {

    public static func paginate(
        for req: Request,
        pageKey: String = Pagination.Defaults.pageKey,
        perPageKey: String = Pagination.Defaults.perPageKey,
        _ sorts: [DatabaseQuery.Sort] = []
    ) throws -> Future<Fluent.Page<Self>> {
        return try Self.query(on: req).sort(sorts).paginate(for: req, pageKey: pageKey, perPageKey: perPageKey)
    }
}
