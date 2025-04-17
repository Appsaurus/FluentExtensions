//
//  QueryBuilder+Sorts.swift
//  
//
//  Created by Brian Strobach on 10/26/21.
//

import Fluent

/// Extension providing enhanced sorting capabilities for QueryBuilder
public extension QueryBuilder {
    /// Applies multiple sort operations to the query in sequence
    /// - Parameter sorts: An array of `DatabaseQuery.Sort` operations to apply
    /// - Returns: The QueryBuilder instance with all sort operations applied
    func sort(_ sorts: [DatabaseQuery.Sort]) -> Self {
        var mSelf = self
        for sort in sorts {
            mSelf = self.sort(sort)
        }
        return mSelf
    }
}
