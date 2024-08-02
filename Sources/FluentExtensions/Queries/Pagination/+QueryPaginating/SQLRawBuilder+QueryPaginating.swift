//
//  SQLRawBuilder+QueryPaginating.swift
//
//
//  Created by Brian Strobach on 9/25/21.
//

import SQLKit
import CollectionConcurrencyKit

extension SQLRawBuilder: QueryPaginating {

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

        guard var sql = self.query as? SQLQueryString else {
            fatalError()
        }

        let total = try await self.count()
        let lowerBound = (page - 1) * per
        sql.appendLiteral("\nLIMIT \(per)\nOFFSET \(lowerBound)")
        let builder = SQLRawBuilder(sql, on: self.database)
        print("Final Query: \n\(builder.serializedSQLString)")
        let rows = try await builder.all()
        return Page(items: rows, metadata: PageMetadata(page: page, per: per, total: total))
    }

    func count() async throws -> Int {
        try await count(rawQuery: serializedSQLString)
    }

    func count(rawQuery: String) async throws -> Int {
        let countQuery = "SELECT COUNT(*) FROM (\(rawQuery)) countQuery;"
        print("COUNT QUERY: \(countQuery)")
        let output = try await self.database.raw(SQLQueryString(stringLiteral: countQuery)).all(decoding: CountResult.self)
        return output.first?.count ?? 0
    }
}

public extension SQLRawBuilder {
    var serializedSQLString: String {
        guard let sql = self.query as? SQLQueryString else {
            fatalError()
        }
        var serializer = SQLSerializer(database: database)
        sql.serialize(to: &serializer)
        return serializer.sql
    }
}
