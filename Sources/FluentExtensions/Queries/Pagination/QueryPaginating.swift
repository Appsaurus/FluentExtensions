//
//  QueryPaginating.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//

public protocol QueryPaginating {
    associatedtype PaginatedData
//    func paginate(for req: Request) -> Future<Page<PaginatedData>>
    func paginate(_ request: PageRequest) -> Future<Page<PaginatedData>>
    func paginate(for request: Request, pageKey: String, perPageKey: String) throws -> Future<Page<PaginatedData>>
}

extension QueryPaginating {
    func paginate(page: Int, perPage: Int) -> Future<Page<Self.PaginatedData>> {
        return paginate(PageRequest(page: page, per: perPage))
    }
}

