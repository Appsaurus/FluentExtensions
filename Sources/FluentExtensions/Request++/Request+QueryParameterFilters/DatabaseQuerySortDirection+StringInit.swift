//
//  DatabaseQuerySortDirection+StringInit.swift
//  
//
//  Created by Brian Strobach on 9/29/21.
//

import Fluent

public extension DatabaseQuery.Sort.Direction {
    init(_ string: String) {
        switch string.lowercased() {
        case "asc", "ascending":
            self = .ascending
        case "desc", "descending":
            self = .descending
        default: self = .custom(string)
        }
    }
}
