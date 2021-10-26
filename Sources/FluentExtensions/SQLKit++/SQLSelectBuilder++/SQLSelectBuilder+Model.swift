//
//  File.swift
//  
//
//  Created by Brian Strobach on 9/23/21.
//

import SQLKit
import Fluent

public extension SQLSelectBuilder {
    func from<M: Model>(_ modelType: M.Type) -> Self {
        return from(modelType.sqlTable)
    }
}
