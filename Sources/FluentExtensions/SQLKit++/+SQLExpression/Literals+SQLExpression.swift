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

/// Extends `Bool` to conform to `SQLExpression`, enabling direct use in SQL queries.
///
/// This extension allows boolean values to be used directly in SQL expressions without manual conversion.
/// The boolean will be serialized using `SQLLiteral.boolean`.
extension Bool: /*@retroactive*/ SQLExpression  {
    public func serialize(to serializer: inout SQLSerializer) {
        SQLLiteral.boolean(self).serialize(to: &serializer)
    }
}

/// Extends `Int` to conform to `SQLExpression`, enabling direct use in SQL queries.
///
/// This extension allows integer values to be used directly in SQL expressions without manual conversion.
/// The integer will be serialized as a numeric literal.
extension Int: /*@retroactive*/ SQLExpression  {
    public func serialize(to serializer: inout SQLSerializer) {
        SQLLiteral.numeric("\(self)").serialize(to: &serializer)
    }
}

/// Extends `Double` to conform to `SQLExpression`, enabling direct use in SQL queries.
///
/// This extension allows floating-point values to be used directly in SQL expressions without manual conversion.
/// The double will be serialized as a numeric literal.
extension Double: /*@retroactive*/ SQLExpression  {
    public func serialize(to serializer: inout SQLSerializer) {
        SQLLiteral.numeric("\(self)").serialize(to: &serializer)
    }
}
