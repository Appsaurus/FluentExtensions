//
//  Request+QueryParameterFilters.swift
//
//
//  Created by Brian Strobach on 9/7/21.
//

import Vapor

public extension Request {
    
    /// Decodes a query parameter filter string into a DatabaseQuery.Filter.
    ///
    /// This method extracts a filter string from the request's query parameters and converts it
    /// into a database filter using the provided builder. The filter can then be used to filter
    /// database queries based on the query parameter values.
    ///
    /// - Parameters:
    ///   - queryParameter: The name of the query parameter containing the filter string. Defaults to "filter".
    ///   - builder: A builder object that defines how to construct the filter from the parameter string.
    ///
    /// - Returns: An optional DatabaseQuery.Filter object that can be applied to database queries.
    ///
    /// - Throws: QueryParameterFilterError.invalidFilterConfiguration if the filter string is missing or invalid.
    ///
    /// - Note: The filter string format should match the specifications defined in the QueryParameterFilter.Builder.
    func decodeParameterFilter<T: Model>(withQueryParameter queryParameter: String = "filter",
                                         builder: QueryParameterFilter.Builder<T>) throws -> DatabaseQuery.Filter? {
        guard let filterString: String = query[queryParameter] else {
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
        return try DatabaseQuery.Filter.build(from: filterString, builder: builder)
    }
}
