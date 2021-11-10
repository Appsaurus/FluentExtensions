//
//  SQLUnion.swift
//  
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit

public struct SQLUnion: SQLExpression {
    public let args: [SQLExpression]

    public init(_ args: SQLExpression...) {
        self.init(args)
    }

    public init(_ args: [SQLExpression]) {
        self.args = args
    }

    public func serialize(to serializer: inout SQLSerializer) {
        let args = args.map(SQLGroupExpression.init)
        guard let first = args.first else { return }
        first.serialize(to: &serializer)
        for arg in args.dropFirst() {
            serializer.write(" UNION ")
            arg.serialize(to: &serializer)
        }
    }
}

public func UNION(_ args: [SQLExpression]) -> SQLUnion {
    SQLUnion(args)
}


public func UNION(_ args: SQLExpression...) -> SQLUnion {
    SQLUnion(args)
}
