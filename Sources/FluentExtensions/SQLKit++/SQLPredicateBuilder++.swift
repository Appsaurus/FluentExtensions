//
//  SQLPredicateBuilder++.swift
//  
//
//  Created by Brian Strobach on 10/25/21.
//

import SQLKit

public extension SQLPredicateBuilder {
    @discardableResult
    func `where`<E>(_ lhs: SQLExpression, _ op: SQLBinaryOperator, _ rhs: E) -> Self
        where E: Encodable
    {
        return self.where(lhs, op, SQLBind(rhs))
    }
}
