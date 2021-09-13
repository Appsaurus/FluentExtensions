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

    func sqlSelect(from table: SQLExpression? = nil) -> SQLSelectBuilder  {
        let builder = sql().select()
        guard let table = table else {
            return builder
        }
        return builder.from(table)
    }

    func sqlSelect<M: Model>(_ modelType: M.Type = M.self) -> SQLSelectBuilder  {
        return sqlSelect().from(M.self)
    }
}

