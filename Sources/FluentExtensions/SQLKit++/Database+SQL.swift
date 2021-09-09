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

    func sqlSelect() throws -> SQLSelectBuilder  {
        return try sql().select()
    }
}
