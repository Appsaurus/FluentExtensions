//
//  SQLCount.swift
//  
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit


public struct SQLCount: SQLExpression {
    public var args: [SQLExpression] = [SQLLiteral.all]
    public var label: SQLExpression = "count"

    public init(_ args: [SQLExpression]? = nil, as label: SQLExpression? = nil) {
        if let args = args, args.count > 0 {
            self.args = args
        }
        if let label = label {
            self.label = label
        }
    }

    public init(_ args: SQLExpression..., as label: SQLExpression? = nil) {
        if args.count > 0 {
            self.args = args
        }
        if let label = label {
            self.label = label
        }

    }

    public func serialize(to serializer: inout SQLSerializer) {
        SQLFunction("COUNT", args: args).as(label).serialize(to: &serializer)
    }
}

public func count(_ args: [SQLExpression]? = nil, as label: SQLExpression? = nil) -> SQLExpression {
    SQLCount(args, as: label)
}

public func count(_ args: SQLExpression..., as label: SQLExpression? = nil) -> SQLExpression {
    SQLCount(args, as: label)
}



