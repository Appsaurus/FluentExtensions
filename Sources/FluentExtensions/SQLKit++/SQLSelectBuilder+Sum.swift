//
//  SQLSelectBuilder+Sum.swift
//  
//
//  Created by Brian Strobach on 9/23/21.
//

import SQLKit

public extension SQLSelectBuilder {

    func sum(_ expression: SQLExpression, as castedType: SQLDataType? = nil, labeled label: String) -> SQLSelectBuilder {
        var function: SQLExpression = SQLFunction.sum(expression)
        if let cast = castedType {
            function = function.cast(as: cast)
        }
        return column(function.as(label))
    }

    func sum<M: Model, Field>(_ key: KeyPath<M, Field>) -> Future<Field.Value?>
        where
            Field: QueryableProperty,
            Field.Model == M
    {
        self.sum(key, labeled: "sum")
            .from(M.sqlTable)
            .all(decoding: SumRow<Field.Value>.self)
            .map { values in
                values.first?.sum
            }
    }
}


public struct SumRow<Value: Codable>: Codable {
    public var sum: Value
}

