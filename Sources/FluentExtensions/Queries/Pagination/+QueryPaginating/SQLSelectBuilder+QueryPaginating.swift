//
//  SQLSelectBuilder+QueryPaginating.swift
//
//
//  Created by Brian Strobach on 9/25/21.
//
import SQLKit
import CollectionConcurrencyKit

/// Errors that can occur during pagination
public enum PaginationError: Error {
    /// The page number was invalid (less than or equal to 0)
    case invalidPageNumber(Int)
    /// The items per page value was invalid (less than or equal to 0)
    case invalidPerSize(Int)
    /// An unspecified error occurred during pagination
    case unspecified(Error)
}

/// Extension adding pagination support to SQLSelectBuilder
extension SQLSelectBuilder: QueryPaginating {
    /// Paginates the results of a SELECT query
    /// - Parameter request: The pagination request containing page number and items per page
    /// - Returns: A Page containing the paginated SQLRows and metadata
    /// - Throws: PaginationError if invalid pagination parameters are provided
    public func paginate(_ request: PageRequest) async throws -> Page<SQLRow> {
        let page = request.page
        let per = request.per

        guard page > 0 else {
            throw PaginationError.invalidPageNumber(page)
        }

        guard per > 0 else {
            throw PaginationError.invalidPerSize(per)
        }

        let total = try await self.count(query: self.select)
        let lowerBound = (page - 1) * per
        self.apply(limit: per, offset: lowerBound)
        let rows = try await self.all()
        return Page(items: rows, metadata: PageMetadata(page: page, per: per, total: total))
    }

    /// Applies limit and offset to the query
    /// - Parameters:
    ///   - limit: Maximum number of rows to return
    ///   - offset: Number of rows to skip
    /// - Returns: Self for method chaining
    @discardableResult
    public func apply(limit: Int, offset: Int) -> Self {
        return self.limit(limit).offset(offset)
    }

    /// Counts the total number of rows that would be returned by the query
    /// - Parameter query: The SELECT query to count
    /// - Returns: The total count of rows
    /// - Throws: Any errors encountered during query execution
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

/// Structure for decoding COUNT query results
public struct CountResult: Codable {
    public let count: Int
}
