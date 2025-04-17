//
//  QueryPaginating.swift
//
//
//  Created by Brian Strobach on 9/25/21.
//
import SQLKit
import CollectionConcurrencyKit

/// A protocol that defines paginated data fetching capabilities.
///
/// Conforming types can provide paginated access to their data, supporting both request-based
/// and manual pagination approaches.
public protocol QueryPaginating {
    /// The type of data being paginated
    associatedtype PaginatedData
    
    /// Paginates data according to the specified page request
    /// - Parameter request: The pagination parameters
    /// - Returns: A page containing the requested data slice
    func paginate(_ request: PageRequest) async throws -> Page<PaginatedData>
    
    /// Paginates data based on request query parameters
    /// - Parameters:
    ///   - request: The incoming request containing pagination parameters
    ///   - pageKey: The query parameter key for the page number
    ///   - perPageKey: The query parameter key for items per page
    /// - Returns: A page containing the requested data slice
    func paginate(for request: Request, pageKey: String, perPageKey: String) async throws -> Page<PaginatedData>
}

extension QueryPaginating {
    /// Default implementation for request-based pagination
    public func paginate(
        for request: Request,
        pageKey: String = Pagination.Defaults.pageKey,
        perPageKey: String = Pagination.Defaults.perPageKey
    ) async throws -> Page<Self.PaginatedData> {
        let pageRequest = try request.query.decodePageRequest()
        return try await self.paginate(pageRequest)
    }

    /// Paginates data using explicit page and per-page values
    /// - Parameters:
    ///   - page: The page number to fetch
    ///   - perPage: The number of items per page
    func paginate(page: Int, perPage: Int) async throws -> Page<Self.PaginatedData> {
        try await paginate(PageRequest(page: page, per: perPage))
    }
}

// MARK: - SQL Row Extensions
extension QueryPaginating where PaginatedData == SQLRow {
    /// Paginates and transforms SQL rows using a custom transformation
    func paginate<D>(_ request: PageRequest,
                     _ transformingDatum: @escaping (SQLRow) throws -> D) async throws -> Page<D> {
        let page = try await self.paginate(request)
        return try page.transformingEachRow(with: transformingDatum)
    }

    /// Paginates and transforms SQL rows from a request using a custom transformation
    func paginate<D>(for request: Request,
                     pageKey: String = Pagination.Defaults.pageKey,
                     perPageKey: String = Pagination.Defaults.perPageKey,
                     _ transformingDatum: @escaping (SQLRow) throws -> D) async throws -> Page<D> {
        let page = try await self.paginate(for: request, pageKey: pageKey, perPageKey: perPageKey)
        return try page.transformingEachRow(with: transformingDatum)
    }

    /// Paginates and transforms SQL rows using explicit pagination parameters
    func paginate<D>(page: Int, perPage: Int, _ transformingDatum: @escaping (SQLRow) throws -> D) async throws -> Page<D> {
        let page = try await self.paginate(page: page, perPage: perPage)
        return try page.transformingEachRow(with: transformingDatum)
    }
}

// MARK: - Page SQL Row Extensions
public extension Page where T == SQLRow {
    /// Transforms each row in the page using a custom transformation
    func transformingEachRow<D>(with transformer: @escaping (SQLRow) throws -> D) throws -> Page<D> {
        let transformedItems = try items.map { try transformer($0) }
        return Page<D>(items: transformedItems, metadata: metadata)
    }

    /// Transforms the entire collection of rows using a custom transformation
    func transformingRows<D>(with transformer: @escaping ([SQLRow]) throws -> [D]) throws -> Page<D> {
        let transformedItems = try transformer(items)
        return Page<D>(items: transformedItems, metadata: metadata)
    }

    /// Decodes rows into a specified Decodable type
    func decodingRows<D>(as type: D.Type = D.self) async throws -> Page<D> where D: Decodable {
        try transformingEachRow(with: { try $0.decode(model: type) })
    }
}

// MARK: - Variadic Row Decoding Extensions
public extension Page where T == SQLRow {
    /// Decodes rows into a tuple of two decodable types
    func decodingRows<M1: Codable, M2: Codable>(
        as model: M1.Type = M1.self,
        _ model2: M2.Type = M2.self
    ) async throws -> Page<(M1, M2)> {
        try transformingEachRow(with: { try $0.decode(model, model2) })
    }

    /// Decodes rows into a tuple of three decodable types
    func decodingRows<M1: Codable, M2: Codable, M3: Codable>(
        as model: M1.Type = M1.self,
        _ model2: M2.Type = M2.self,
        _ model3: M3.Type = M3.self
    ) async throws -> Page<(M1, M2, M3)> {
        try transformingEachRow(with: { try $0.decode(model, model2, model3) })
    }

    /// Decodes rows into a tuple of four decodable types
    func decodingRows<M1: Codable, M2: Codable, M3: Codable, M4: Codable>(
        as model: M1.Type = M1.self,
        _ model2: M2.Type = M2.self,
        _ model3: M3.Type = M3.self,
        _ model4: M4.Type = M4.self
    ) async throws -> Page<(M1, M2, M3, M4)> {
        try transformingEachRow(with: { try $0.decode(model, model2, model3, model4) })
    }
}

// MARK: - SQL Row Decoding Extensions
public extension SQLRow {
    /// Decodes the row into a tuple of two decodable types
    func decode<M1: Codable, M2: Codable>(
        _ model: M1.Type = M1.self,
        _ model2: M2.Type = M2.self
    ) throws -> (M1, M2) {
        return (try decode(model: model), try decode(model: model2))
    }

    /// Decodes the row into a tuple of three decodable types
    func decode<M1: Codable, M2: Codable, M3: Codable>(
        _ model: M1.Type = M1.self,
        _ model2: M2.Type = M2.self,
        _ model3: M3.Type = M3.self
    ) throws -> (M1, M2, M3) {
        return (try decode(model: model), try decode(model: model2), try decode(model: model3))
    }

    /// Decodes the row into a tuple of four decodable types
    func decode<M1: Codable, M2: Codable, M3: Codable, M4: Codable>(
        _ model: M1.Type = M1.self,
        _ model2: M2.Type = M2.self,
        _ model3: M3.Type = M3.self,
        _ model4: M4.Type = M4.self
    ) throws -> (M1, M2, M3, M4) {
        return (try decode(model: model), try decode(model: model2), try decode(model: model3), try decode(model: model4))
    }
}
