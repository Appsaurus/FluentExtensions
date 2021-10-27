//
//  QueryBuilder+Sorts.swift
//  
//
//  Created by Brian Strobach on 10/26/21.
//

import Fluent

extension QueryBuilder {
    func sort(_ sorts: [DatabaseQuery.Sort]) -> Self {
        var mSelf = self
        for sort in sorts {
            mSelf = self.sort(sort)
        }
        return mSelf
    }
}
