//
//  Model+RequireIDs.swift
//  
//
//  Created by Brian Strobach on 10/14/21.
//

import Fluent

public extension Collection where Element: Model{
    func requireIDs() throws -> [Element.IDValue] {
        return try compactMap { try $0.requireID()}
    }

    var ids: [Element.IDValue] {
        return compactMap {  $0.id}
    }
}
