//
//  Model+CRUDPath.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 8/26/24.
//

import Swiftest

extension Model {
    static var crudPathName: String {
        return schemaOrAlias
            .removingSuffix("Entity")
            .pluralized
            .formatted(as: .hyphenated)
    }
}

//Simple solution for our use case. Obviously not to be used as a generalized solution.
extension String {
    var pluralized: String {
        if ends(with: "ings") {
            return self
        }
        if ends(with: "y") {
            return "\(self.dropLast())ies"
        }
        if ends(with: "s") {
            return "\(self)es"
        }
        return "\(self)s"
    }
}
