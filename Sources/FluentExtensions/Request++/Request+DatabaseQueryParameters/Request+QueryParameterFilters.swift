//
//  Request+QueryParameterFilters.swift
//  
//
//  Created by Brian Strobach on 9/7/21.
//

import Vapor

public extension Request {
    
    func decodeParameterFilter<T: Model>(withQueryParameter queryParameter: String = "filter",
                                         builder: QueryParameterFilter.Builder<T>) throws -> DatabaseQuery.Filter? {
        guard let filterString: String = query[queryParameter] else {
            throw QueryParameterFilterError.invalidFilterConfiguration
        }
        return try DatabaseQuery.Filter.build(from: filterString, builder: builder)
    }
}



