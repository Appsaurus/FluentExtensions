//
//  DatabaseQuery++.swift
//  
//
//  Created by Brian Strobach on 9/7/21.
//

import Fluent

extension DatabaseQuery.Filter.Method {
    static var inSubSet: Self {
        .subset(inverse: false)
    }

    static var notInSubSet: Self {
        .subset(inverse: true)
    }
}
