//
//  SQLCount.swift
//  
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit


public struct SQLCount: SQLExpression {
    public var args: [SQLExpression] = [SQLLiteral.all]
    public var label: String = "count"

    public init(_ args: [SQLExpression]? = nil, as label: String? = nil) {
        if let args = args, args.count > 0 {
            self.args = args
        }
        if let label = label {
            self.label = label
        }
    }

    public init(_ args: SQLExpression..., as label: String? = nil) {
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

public func count(_ args: [SQLExpression]? = nil, as label: String? = nil) -> SQLExpression {
    SQLCount(args, as: label)
}

public func count(_ args: SQLExpression..., as label: String? = nil) -> SQLExpression {
    SQLCount(args, as: label)
}



