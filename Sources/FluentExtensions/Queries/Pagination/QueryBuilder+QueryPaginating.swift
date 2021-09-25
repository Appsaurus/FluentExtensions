//
//  QueryBuilder+QueryPaginating.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//

extension QueryBuilder: QueryPaginating {
    public typealias PaginatedData = Model

    public func paginate(
        for request: Request,
        pageKey: String = Pagination.Defaults.pageKey,
        perPageKey: String = Pagination.Defaults.perPageKey
    ) throws -> Future<Page<Model>> {

        let pageRequest = try request.query.decodePageRequest()
        return self.paginate(pageRequest)
    }
}

