//
//  SQLCoalesce.swift
//
//
//  Created by Brian Strobach on 9/23/21.
//

import SQLKit

/// Returns the first non-null value in a list of expressions.
///
/// The COALESCE function returns the first non-null expression in a list.
/// This is useful for providing fallback values in SQL queries.
///
/// Example:
/// ```swift
/// // Returns user.name if not null, otherwise returns "Anonymous"
/// COALESCE(user.name, "Anonymous")
/// ```
///
/// - Parameter expressions: A variadic list of SQL expressions to evaluate
/// - Returns: A SQLFunction representing the COALESCE operation
public func COALESCE(_ expressions: SQLExpression...) -> SQLFunction {
    .coalesce(expressions)
}

/// Array variant of COALESCE that accepts an array of expressions instead of variadic parameters.
///
/// - Parameter expressions: An array of SQL expressions to evaluate
/// - Returns: A SQLFunction representing the COALESCE operation
public func COALESCE(_ expressions: [SQLExpression]) -> SQLFunction {
    .coalesce(expressions)
}
