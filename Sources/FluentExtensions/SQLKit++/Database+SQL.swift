//
//  Database+SQL.swift
//  
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit

public extension Database {

    func sql() throws -> SQLDatabase  {
        return try (self as? SQLDatabase).unwrapped(or: Abort(.internalServerError))
    }

    func sqlSelect(from table: SQLExpression? = nil) throws -> SQLSelectBuilder  {
        let builder = try sql().select()
        guard let table = table else {
            return builder
        }
        return builder.from(table)
    }

    func sqlSelect<M: Model>(_ modelType: M.Type = M.self) throws -> SQLSelectBuilder  {
        return try sqlSelect().from(M.sqlTable)
    }
}
