//
//  Literals+SQLExpression.swift
//  
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit
import Vapor
//extension String: SQLExpression  {
//    public func serialize(to serializer: inout SQLSerializer) {
//        SQLRaw(self).serialize(to: &serializer)
//    }
//}

extension Bool: /*@retroactive*/ SQLExpression  {
    public func serialize(to serializer: inout SQLSerializer) {
        SQLLiteral.boolean(self).serialize(to: &serializer)
    }
}

extension Int: /*@retroactive*/ SQLExpression  {
    public func serialize(to serializer: inout SQLSerializer) {
        SQLLiteral.numeric("\(self)").serialize(to: &serializer)
    }
}

extension Double: /*@retroactive*/ SQLExpression  {
    public func serialize(to serializer: inout SQLSerializer) {
        SQLLiteral.numeric("\(self)").serialize(to: &serializer)
    }
}
