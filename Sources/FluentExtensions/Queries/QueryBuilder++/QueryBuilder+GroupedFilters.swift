//
//  QueryBuilder+GroupedFilters.swift
//  
//
//  Created by Brian Strobach on 9/14/21.
//

import FluentKit


public extension QueryBuilder {
    func or(_ values: DatabaseQuery.Filter...) -> Self {
        return group(.or) { (or) in
            for value in values{
                or.filter(value)
            }
        }
    }

    func and(_ values: DatabaseQuery.Filter...) -> Self {
        return group(.and) { (and) in
            for value in values{
                and.filter(value)
            }
        }
    }
}
