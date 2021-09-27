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

public extension Future where Value == Page<SQLRow> {

    func transformingEachRow<D>(with transformer: @escaping (SQLRow) throws -> D) -> EventLoopFuture<Page<D>> {
        self.flatMapThrowing {
            try $0.transformDatum(with: transformer)
        }
    }

    func transformingRows<D>(with transformer: @escaping ([SQLRow]) throws -> [D]) -> EventLoopFuture<Page<D>> {
        self.flatMapThrowing {
            try $0.transformData(with: transformer)
        }
    }

    func decodingRows<D>(as type: D.Type = D.self) -> EventLoopFuture<Page<D>> where D: Decodable {
        transformingEachRow(with: { try $0.decode(model: type) })
    }
}

// Variadic decoding

public extension Future where Value == Page<SQLRow> {
    func decodingRows<M1: Codable, M2: Codable>(as model: M1.Type = M1.self,
                                                _ model2: M2.Type = M2.self) -> Future<Page<(M1, M2)>> {
        return transformingEachRow(with: {try $0.decode(model, model2)})
    }

    func decodingRows<M1: Codable, M2: Codable, M3: Codable>(as model: M1.Type = M1.self,
                                                             _ model2: M2.Type = M2.self,
                                                             _ model3: M3.Type = M3.self) -> Future<Page<(M1, M2, M3)>> {
        return transformingEachRow(with: {try $0.decode(model, model2, model3)})
    }

    func decodingRows<M1: Codable, M2: Codable, M3: Codable, M4: Codable>(as model: M1.Type = M1.self,
                                                                          _ model2: M2.Type = M2.self,
                                                                          _ model3: M3.Type = M3.self,
                                                                          _ model4: M4.Type = M4.self) -> Future<Page<(M1, M2, M3, M4)>> {
        return transformingEachRow(with: {try $0.decode(model, model2, model3, model4)})
    }
}


public extension SQLRow {
    func decode<M1: Codable, M2: Codable>(_ model: M1.Type = M1.self, _ model2: M2.Type = M2.self) throws -> (M1, M2) {
        return (try decode(model: model), try decode(model: model2))
    }

    func decode<M1: Codable, M2: Codable, M3: Codable>(_ model: M1.Type = M1.self,
                                                             _ model2: M2.Type = M2.self,
                                                             _ model3: M3.Type = M3.self) throws -> (M1, M2, M3) {
        return (try decode(model: model), try decode(model: model2), try decode(model: model3))
    }

    func decode<M1: Codable, M2: Codable, M3: Codable, M4: Codable>(_ model: M1.Type = M1.self,
                                                                          _ model2: M2.Type = M2.self,
                                                                          _ model3: M3.Type = M3.self,
                                                                          _ model4: M4.Type = M4.self) throws -> (M1, M2, M3, M4) {
        return (try decode(model: model), try decode(model: model2), try decode(model: model3), try decode(model: model4))
    }
}
