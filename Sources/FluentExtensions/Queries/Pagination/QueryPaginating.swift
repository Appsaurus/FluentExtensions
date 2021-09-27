//
//  QueryPaginating.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//
import SQLKit

public protocol QueryPaginating {
    associatedtype PaginatedData
//    func paginate(for req: Request) -> Future<Page<PaginatedData>>
    func paginate(_ request: PageRequest) -> Future<Page<PaginatedData>>
    func paginate(for request: Request, pageKey: String, perPageKey: String) throws -> Future<Page<PaginatedData>>
}

extension QueryPaginating {

    public func paginate(
        for request: Request,
        pageKey: String = Pagination.Defaults.pageKey,
        perPageKey: String = Pagination.Defaults.perPageKey
    ) throws -> Future<Page<PaginatedData>> {
        let pageRequest = try request.query.decodePageRequest()
        return self.paginate(pageRequest)
    }

    func paginate(page: Int, perPage: Int) -> Future<Page<Self.PaginatedData>> {
        return paginate(PageRequest(page: page, per: perPage))
    }
}


extension QueryPaginating where PaginatedData == SQLRow {
    func paginate<D>(_ request: PageRequest,
                     _ transformingDatum: @escaping (SQLRow) throws -> D) -> Future<Page<D>> {
        self.paginate(request).transformingEachRow(with: transformingDatum)
    }
    func paginate<D>(for request: Request,
                     pageKey: String = Pagination.Defaults.pageKey,
                     perPageKey: String = Pagination.Defaults.perPageKey,
                     _ transformingDatum: @escaping (SQLRow) throws -> D) throws -> Future<Page<D>> {
        try self.paginate(for: request, pageKey: pageKey, perPageKey: perPageKey).transformingEachRow(with: transformingDatum)
    }

    func paginate<D>(page: Int, perPage: Int, _ transformingDatum: @escaping (SQLRow) throws -> D) -> Future<Page<D>> {
        self.paginate(page: page, perPage: perPage).transformingEachRow(with: transformingDatum)
    }
}

extension Future where Value == Page<SQLRow> {

    public func transformingEachRow<D>(with transformer: @escaping (SQLRow) throws -> D) -> EventLoopFuture<Page<D>> {
        self.flatMapThrowing {
            try $0.transformDatum(with: transformer)
        }
    }

    public func transformingRows<D>(with transformer: @escaping ([SQLRow]) throws -> [D]) -> EventLoopFuture<Page<D>> {
        self.flatMapThrowing {
            try $0.transformData(with: transformer)
        }
    }

    public func decodingRows<D>(as type: D.Type = D.self) -> EventLoopFuture<Page<D>> where D: Decodable {
        transformingEachRow(with: { try $0.decode(model: type) })
    }
}
