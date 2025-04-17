//
//  SQLRawBuilder+QueryPaginating.swift
//
//
//  Created by Brian Strobach on 9/25/21.
//

import SQLKit
import CollectionConcurrencyKit

/// Extension adding pagination support to SQLRawBuilder
extension SQLRawBuilder: QueryPaginating {
    /// Paginates the results of a raw SQL query
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

        guard var sql = self.query as? SQLQueryString else {
            fatalError()
        }

        let total = try await self.count()
        let lowerBound = (page - 1) * per
        sql.appendLiteral("\nLIMIT \(per)\nOFFSET \(lowerBound)")
        let builder = SQLRawBuilder(sql, on: self.database)
        let rows = try await builder.all()
        return Page(items: rows, metadata: PageMetadata(page: page, per: per, total: total))
    }

    /// Counts the total number of rows in the query result
    /// - Returns: The total count of rows
    /// - Throws: Any errors encountered during query execution
    func count() async throws -> Int {
        try await count(rawQuery: serializedSQLString)
    }

    /// Counts the total number of rows for a given raw SQL query
    /// - Parameter rawQuery: The SQL query string
    /// - Returns: The total count of rows
    /// - Throws: Any errors encountered during query execution
    func count(rawQuery: String) async throws -> Int {
        let countQuery = "SELECT COUNT(*) FROM (\(rawQuery)) countQuery;"
        let output = try await self.database.raw(SQLQueryString(stringLiteral: countQuery)).all(decoding: CountResult.self)
        return output.first?.count ?? 0
    }
}

public extension SQLRawBuilder {
    /// The serialized SQL string representation of the query
    var serializedSQLString: String {
        guard let sql = self.query as? SQLQueryString else {
            fatalError()
        }
        var serializer = SQLSerializer(database: database)
        sql.serialize(to: &serializer)
        return serializer.sql
    }
}
