//
//  Database+SQL.swift
//  
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit

public extension Database {

    func sql() -> SQLDatabase  {
        guard let sqlDatabase = self as? SQLDatabase else {
            fatalError("\(self) is not an SQLDatabase")
        }
        return sqlDatabase
    }

    func select() -> SQLSelectBuilder  {
        sql().select()
    }
    func select(from table: SQLExpression) -> SQLSelectBuilder  {
        select().from(table)
    }

    func select<M: Model>(_ modelType: M.Type) -> SQLSelectBuilder  {
        select().from(M.self)
    }

    func sqlRaw(_ query: String) ->  SQLRawBuilder{
        sql().raw(query)
    }
}

public extension SQLDatabase {
    func raw(_ sql: String) -> SQLRawBuilder {
        return raw(SQLQueryString(sql))
    }
}

public extension Database {
    func query<R: Decodable>(_ rawQuery: String, decoding result: R.Type = R.self) -> Future<[R]>{
        sqlRaw(rawQuery).all(decoding: result)
    }
}

public extension Request {
    func query<R: Decodable>(_ rawQuery: String,
                             decoding result: R.Type = R.self) -> Future<[R]>{
        db.query(rawQuery, decoding: result)
    }
}

