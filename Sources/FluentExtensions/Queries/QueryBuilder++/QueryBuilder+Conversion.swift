//
//  File.swift
//  
//
//  Created by Brian Strobach on 9/23/21.
//

import Fluent
import SQLKit
import FluentSQL

public extension QueryBuilder {
    func convert(with delegate: SQLConverterDelegate) throws -> SQLQueryBuilder {
        let converter = SQLQueryConverter(delegate: delegate)
        let expression = converter.convert(self.query)
        let db = self.database.sql()
        switch query.action {
        case .read, .aggregate:
            let b = SQLSelectBuilder(on: db)
            b.select = try expression.unwrap()
            return b
        case .create:
            return SQLInsertBuilder(try expression.unwrap(), on: db)
        case .update:
            return SQLUpdateBuilder(try expression.unwrap(), on: db)
        case .delete:
            return SQLDeleteBuilder(try expression.unwrap(), on: db)
        case .custom(_):
            return SQLRawBuilder(SQLQueryString((try expression.unwrap(as: SQLRaw.self)).sql), on: db)
        }        
    }
}


private extension SQLExpression {
    func unwrap<T>(as type: T.Type = T.self, or error: Error = Abort(.badRequest)) throws -> T {
        return try (self as? T).unwrapped(or: error)
    }
}
