import SQLKit

/// Extends `Database` with convenient SQL functionality and type-safe query builders
public extension Database {
    /// Converts the current database instance to an `SQLDatabase`
    /// - Returns: The database as an `SQLDatabase`
    /// - Warning: Will crash if the database is not SQL-compatible
    func sql() -> SQLDatabase {
        guard let sqlDatabase = self as? SQLDatabase else {
            fatalError("\(self) is not an SQLDatabase")
        }
        return sqlDatabase
    }

    /// Creates a new SQL SELECT query builder
    /// - Returns: A new ``SQLSelectBuilder`` instance
    func select() -> SQLSelectBuilder {
        sql().select()
    }

    /// Creates a new SQL SELECT query builder with a specified table
    /// - Parameter table: The SQL table expression to select from
    /// - Returns: A configured ``SQLSelectBuilder`` instance
    func select(from table: SQLExpression) -> SQLSelectBuilder {
        select().from(table)
    }

    /// Creates a new SQL SELECT query builder for a specific Fluent model
    /// - Parameter modelType: The model type to create the select query for
    /// - Returns: A configured ``SQLSelectBuilder`` instance targeting the model's table
    func select<M: Model>(_ modelType: M.Type) -> SQLSelectBuilder {
        select().from(M.self)
    }

    /// Creates a raw SQL query builder
    /// - Parameter query: The raw SQL query string
    /// - Returns: A new ``SQLRawBuilder`` instance
    func sqlRaw(_ query: String) -> SQLRawBuilder {
        sql().raw(query)
    }
}

public extension SQLDatabase {
    /// Creates a raw SQL query builder from a string
    /// - Parameter sql: The raw SQL query string
    /// - Returns: A new ``SQLRawBuilder`` instance
    func raw(_ sql: String) -> SQLRawBuilder {
        return raw(SQLQueryString(sql))
    }
}

public extension Database {
    /// Executes a raw SQL query and decodes the results into a specified type
    /// - Parameters:
    ///   - rawQuery: The raw SQL query string to execute
    ///   - result: The type to decode the results into
    /// - Returns: An array of decoded results
    /// - Throws: Any errors that occur during query execution or decoding
    ///
    /// Example:
    /// ```swift
    /// struct UserCount: Decodable {
    ///     let count: Int
    /// }
    /// let counts = try await db.query("SELECT COUNT(*) as count FROM users", decoding: UserCount.self)
    /// ```
    func query<R: Decodable>(_ rawQuery: String, decoding result: R.Type = R.self) async throws -> [R] {
        try await sqlRaw(rawQuery).all(decoding: result)
    }
}

public extension Request {
    /// Executes a raw SQL query on the request's database and decodes the results into a specified type
    /// - Parameters:
    ///   - rawQuery: The raw SQL query string to execute
    ///   - result: The type to decode the results into
    /// - Returns: An array of decoded results
    /// - Throws: Any errors that occur during query execution or decoding
    func query<R: Decodable>(_ rawQuery: String, decoding result: R.Type = R.self) async throws -> [R] {
        try await db.query(rawQuery, decoding: result)
    }
}
