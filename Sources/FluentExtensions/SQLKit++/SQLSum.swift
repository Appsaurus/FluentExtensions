//
//  File.swift
//  
//
//  Created by Brian Strobach on 9/23/21.
//
import SQLKit

public extension SQLSelectBuilder {

    func sum(_ expression: SQLExpression, as label: String) -> SQLSelectBuilder {
        column(SQLFunction.sum(expression).as(label))
    }

    func sum<M: Model, Field>(_ key: KeyPath<M, Field>) -> Future<Field.Value?>
        where
            Field: QueryableProperty,
            Field.Model == M,
            Field.Value == Int
    {
        self.from(M.sqlTable)
            .sum(key, as: "sum")
            .all(decoding: SumRow<Field.Value>.self)
            .map { values in
                values.first?.sum
            }
    }
}

public struct SumRow<Value: Codable>: Codable {
    public var sum: Value
}

public extension SQLFunction {

    static func sum(_ expression: SQLExpression) -> SQLFunction {
        return .init("SUM", args: expression)
    }
}

public func sum(_ expression: SQLExpression) -> SQLFunction {
    .sum(expression)
}
