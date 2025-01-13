//
//  SQLSelectBuilder+QueryPaginating.swift
//
//
//  Created by Brian Strobach on 9/25/21.
//
import SQLKit
import CollectionConcurrencyKit

public enum PaginationError: Error {
    case invalidPageNumber(Int)
    case invalidPerSize(Int)
    case unspecified(Error)
}

extension SQLSelectBuilder: QueryPaginating {
    public typealias PaginatedData = SQLRow

    public func paginate(_ request: PageRequest) async throws -> Page<SQLRow> {
        let page = request.page
        let per = request.per

        // Make sure the current page is greater than 0
        guard page > 0 else {
            throw PaginationError.invalidPageNumber(page)
        }

        // Per-page also must be greater than zero
        guard per > 0 else {
            throw PaginationError.invalidPerSize(per)
        }

        // Return a full count
        let total = try await self.count(query: self.select)
        let lowerBound = (page - 1) * per
        self.apply(limit: per, offset: lowerBound)
        let rows = try await self.all()
        return Page(items: rows, metadata: PageMetadata(page: page, per: per, total: total))
    }

    @discardableResult
    public func apply(limit: Int, offset: Int) -> Self {
        return self.limit(limit).offset(offset)
    }

    public func count(query: SQLSelect) async throws -> Int {
        var query = query
        query.columns = []
        query.orderBy = []
        let builder = SQLSelectBuilder(on: self.database)
        builder.select = query

        let result = try await builder.column(COUNT()).first(decoding: CountResult.self)
        return result?.count ?? 0
    }
}

public struct CountResult: Codable {
    public let count: Int
}
