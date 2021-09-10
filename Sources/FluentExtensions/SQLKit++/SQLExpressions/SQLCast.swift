//
//  SQLCast.swift
//  
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit

public struct SQLCast: SQLExpression {
    public var expression: SQLExpression
    public var type: SQLExpression

    public init(_ expression: SQLExpression, as type: SQLExpression) {
        self.expression = expression
        self.type = type
    }

    public func serialize(to serializer: inout SQLSerializer) {
        serializer.write("CAST(")
        self.expression.serialize(to: &serializer)
        serializer.write(" AS ")
        self.type.serialize(to: &serializer)
        serializer.write(")")
    }
}

public extension SQLExpression {
    func cast(as type: SQLExpression) -> SQLCast {
        return SQLCast(self, as: type)
    }
}
