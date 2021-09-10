//
//  SQLCase.swift
//  
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit

public struct SQLCase: SQLExpression {
    public var cases: [(condition: SQLExpression, predicate: SQLExpression)]
    public var alternative: SQLExpression?

    public init(when cases: [(SQLExpression, SQLExpression)], `else`: SQLExpression? = nil) {
        self.cases = cases
        self.alternative = `else`
    }
    public init(when cases: (SQLExpression, SQLExpression)..., `else`: SQLExpression? = nil) {
        self.cases = cases
        self.alternative = `else`
    }
    public func serialize(to serializer: inout SQLSerializer) {
        serializer.write("CASE")
        cases.forEach {
            serializer.write(" WHEN ")
            $0.condition.serialize(to: &serializer)
            serializer.write(" THEN ")
            $0.predicate.serialize(to: &serializer)
        }
        alternative.map {
            serializer.write(" ELSE ")
            $0.serialize(to: &serializer)
        }
        serializer.write(" END")
    }
}

public extension SQLExpression {
    func `case`(when cases: [(condition: SQLExpression, predicate: SQLExpression)], `else`: SQLExpression? = nil) -> SQLCase {
        return SQLCase(when: cases, else: `else`)
    }
    func `case`(when cases: (condition: SQLExpression, predicate: SQLExpression)..., `else`: SQLExpression? = nil) -> SQLCase {
        return SQLCase(when: cases, else: `else`)
    }
}
