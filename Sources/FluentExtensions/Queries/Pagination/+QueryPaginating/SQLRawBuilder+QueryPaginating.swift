//
//  SQLRawBuilder+QueryPaginating.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//

import SQLKit

extension SQLRawBuilder: QueryPaginating {

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


        guard var sql = self.query as? SQLQueryString else {
            fatalError()
        }

        return self.count().flatMap { total in
            let lowerBound = (page - 1) * per
            sql.appendLiteral("\nLIMIT \(per)\nOFFSET \(lowerBound)")
            let builder = SQLRawBuilder(sql, on: self.database)
            print("Final Query: \n\(builder.serializedSQLString)")
            return builder.all().tryMap { rows in
                Page(items: rows, metadata: PageMetadata(page: page, per: per, total: total))
            }
        }
    }

    func count() -> EventLoopFuture<Int> {
        count(rawQuery: serializedSQLString)
    }
    func count(rawQuery: String) -> EventLoopFuture<Int> {
        let countQuery = "SELECT COUNT(*) FROM (\(rawQuery)) countQuery;"
        print("COUNT QUERY: \(countQuery)")
        return self.database.raw(SQLQueryString(stringLiteral: countQuery)).all(decoding: CountResult.self).map({ output in
            return output.first?.count ?? 0
        })
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

