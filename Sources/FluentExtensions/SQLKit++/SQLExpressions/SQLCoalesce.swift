//
//  SQLCoalesce.swift
//  
//
//  Created by Brian Strobach on 9/23/21.
//

import SQLKit

public func COALESCE(_ expressions: SQLExpression...) -> SQLFunction {
    .coalesce(expressions)
}

public func COALESCE(_ expressions: [SQLExpression]) -> SQLFunction {
    .coalesce(expressions)
}
