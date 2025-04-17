//
//  QueryBuilder+Conversion.swift
//  
//
//  Created by Brian Strobach on 9/23/21.
//

import Fluent
import SQLKit
import FluentSQL

/// Extension providing SQL conversion capabilities to ``QueryBuilder``
public extension QueryBuilder {
    /// Converts the current query builder into a SQLKit query builder using the provided delegate.
    ///
    /// This method enables seamless conversion between Fluent's query builder and SQLKit's query builder,
    /// allowing for more complex SQL operations when needed.
    ///
    /// ```swift
    /// let sqlBuilder = try queryBuilder.convert(with: SQLConverterDelegate())
    /// ```
    ///
    /// - Parameter delegate: The ``SQLConverterDelegate`` instance used to perform the conversion
    /// - Returns: A ``SQLQueryBuilder`` instance representing the converted query
    /// - Throws: An error if the conversion process fails
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

/// Private extension to handle SQL expression unwrapping
private extension SQLExpression {
    /// Attempts to unwrap the SQL expression as a specific type
    ///
    /// - Parameters:
    ///   - type: The expected type to unwrap the expression as
    ///   - error: The error to throw if unwrapping fails
    /// - Returns: The unwrapped value of the specified type
    /// - Throws: The specified error if unwrapping fails
    func unwrap<T>(as type: T.Type = T.self, or error: Error = Abort(.badRequest)) throws -> T {
        return try (self as? T).unwrapped(or: error)
    }
}
