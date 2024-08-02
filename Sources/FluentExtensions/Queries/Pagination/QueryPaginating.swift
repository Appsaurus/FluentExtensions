//
//  QueryPaginating.swift
//
//
//  Created by Brian Strobach on 9/25/21.
//
import SQLKit
import CollectionConcurrencyKit

public protocol QueryPaginating {
    associatedtype PaginatedData
    func paginate(_ request: PageRequest) async throws -> Page<PaginatedData>
    func paginate(for request: Request, pageKey: String, perPageKey: String) async throws -> Page<PaginatedData>
}

extension QueryPaginating {
    public func paginate(
        for request: Request,
        pageKey: String = Pagination.Defaults.pageKey,
        perPageKey: String = Pagination.Defaults.perPageKey
    ) async throws -> Page<Self.PaginatedData> {
        let pageRequest = try request.query.decodePageRequest()
        return try await self.paginate(pageRequest)
    }

    func paginate(page: Int, perPage: Int) async throws -> Page<Self.PaginatedData> {
        try await paginate(PageRequest(page: page, per: perPage))
    }
}

extension QueryPaginating where PaginatedData == SQLRow {
    func paginate<D>(_ request: PageRequest,
                     _ transformingDatum: @escaping (SQLRow) throws -> D) async throws -> Page<D> {
        let page = try await self.paginate(request)
        return try page.transformingEachRow(with: transformingDatum)
    }

    func paginate<D>(for request: Request,
                     pageKey: String = Pagination.Defaults.pageKey,
                     perPageKey: String = Pagination.Defaults.perPageKey,
                     _ transformingDatum: @escaping (SQLRow) throws -> D) async throws -> Page<D> {
        let page = try await self.paginate(for: request, pageKey: pageKey, perPageKey: perPageKey)
        return try page.transformingEachRow(with: transformingDatum)
    }

    func paginate<D>(page: Int, perPage: Int, _ transformingDatum: @escaping (SQLRow) throws -> D) async throws -> Page<D> {
        let page = try await self.paginate(page: page, perPage: perPage)
        return try page.transformingEachRow(with: transformingDatum)
    }
}

public extension Page where T == SQLRow {
    func transformingEachRow<D>(with transformer: @escaping (SQLRow) throws -> D) throws -> Page<D> {
        let transformedItems = try items.map { try transformer($0) }
        return Page<D>(items: transformedItems, metadata: metadata)
    }

    func transformingRows<D>(with transformer: @escaping ([SQLRow]) throws -> [D]) throws -> Page<D> {
        let transformedItems = try transformer(items)
        return Page<D>(items: transformedItems, metadata: metadata)
    }

    func decodingRows<D>(as type: D.Type = D.self) async throws -> Page<D> where D: Decodable {
        try transformingEachRow(with: { try $0.decode(model: type) })
    }
}

// Variadic decoding

public extension Page where T == SQLRow {
    func decodingRows<M1: Codable, M2: Codable>(as model: M1.Type = M1.self,
                                                _ model2: M2.Type = M2.self) async throws -> Page<(M1, M2)> {
        try transformingEachRow(with: { try $0.decode(model, model2) })
    }

    func decodingRows<M1: Codable, M2: Codable, M3: Codable>(as model: M1.Type = M1.self,
                                                             _ model2: M2.Type = M2.self,
                                                             _ model3: M3.Type = M3.self) async throws -> Page<(M1, M2, M3)> {
        try transformingEachRow(with: { try $0.decode(model, model2, model3) })
    }

    func decodingRows<M1: Codable, M2: Codable, M3: Codable, M4: Codable>(as model: M1.Type = M1.self,
                                                                          _ model2: M2.Type = M2.self,
                                                                          _ model3: M3.Type = M3.self,
                                                                          _ model4: M4.Type = M4.self) async throws -> Page<(M1, M2, M3, M4)> {
        try transformingEachRow(with: { try $0.decode(model, model2, model3, model4) })
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
