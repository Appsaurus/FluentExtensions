//
//  SQLSelectBuilder+QueryPaginating.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//
import SQLKit

public enum PaginationError: Error {
    case invalidPageNumber(Int)
    case invalidPerSize(Int)
    case unspecified(Error)
}


extension SQLSelectBuilder: QueryPaginating {
    public typealias PaginatedData = SQLRow

    public func paginate(_ request: PageRequest) -> Future<Page<SQLRow>> {
        let page = request.page
        let per = request.per

        // Make sure the current page is greater than 0
        guard page > 0 else {
            return self.database.eventLoop.fail(with: PaginationError.invalidPageNumber(page))
        }

        // Per-page also must be greater than zero
        guard per > 0 else {
            return self.database.eventLoop.fail(with: PaginationError.invalidPerSize(per))
        }

        // Return a full count
        return self.count(query: self.select).tryFlatMap { total in
            let lowerBound = (page - 1) * per
            self.apply(limit: per, offset: lowerBound)
            return self.all().tryMap { rows in
                Page(items: rows, metadata: PageMetadata(page: page, per: per, total: total))
            }
        }
    }

    @discardableResult
    public func apply(limit: Int, offset: Int) -> Self {
        return self.limit(limit).offset(offset)
    }

    public func count(query: SQLSelect) -> EventLoopFuture<Int> {
        var query = query
        query.columns = []
        query.orderBy = []
        let builder = SQLSelectBuilder(on: self.database)
        builder.select = query

        return builder.column(COUNT()).first(decoding: CountResult.self).map({$0?.count}).unwrap(orElse: {0})
    }
}

public struct CountResult: Codable {
    public let count: Int
}


