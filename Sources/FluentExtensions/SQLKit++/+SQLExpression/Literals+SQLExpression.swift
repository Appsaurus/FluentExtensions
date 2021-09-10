//
//  Literals+SQLExpression.swift
//  
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit

extension String: SQLExpression  {
    public func serialize(to serializer: inout SQLSerializer) {
        SQLLiteral.string(self).serialize(to: &serializer)
    }
}

extension Bool: SQLExpression  {
    public func serialize(to serializer: inout SQLSerializer) {
        SQLLiteral.boolean(self).serialize(to: &serializer)
    }
}

extension Int: SQLExpression  {
    public func serialize(to serializer: inout SQLSerializer) {
        SQLLiteral.numeric("\(self)").serialize(to: &serializer)
    }
}

extension Double: SQLExpression  {
    public func serialize(to serializer: inout SQLSerializer) {
        SQLLiteral.numeric("\(self)").serialize(to: &serializer)
    }
}
