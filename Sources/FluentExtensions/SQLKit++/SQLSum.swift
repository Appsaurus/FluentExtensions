//
//  File.swift
//  
//
//  Created by Brian Strobach on 9/23/21.
//
import SQLKit


//private class SwiftToSQLTypeConverter {
//    static func convert(type: Any.Type) -> SQLDataType {
//        switch type {
//            case is Int.self:
//            case is Float.self, Double.self:
//                break
//        }
//    }
//}
public extension SQLSelectBuilder {

    func sum(_ expression: SQLExpression, as castedType: Any.Type = Double.self, labeled label: String) -> SQLSelectBuilder {
        var function: SQLExpression = SQLFunction.sum(expression)
        switch castedType {
            case is Int.Type:
                function = function.cast(as: .int)
            default: break
        }
        return column(function.as(label))
    }

    func sum<M: Model, Field>(_ key: KeyPath<M, Field>) -> Future<Field.Value?>
        where
            Field: QueryableProperty,
            Field.Model == M
    {
        self.sum(key, as: Field.Value.self, labeled: "sum")
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

public extension SQLFunction {

    static func sum(_ expression: SQLExpression) -> SQLFunction {
        return .init("SUM", args: expression)
    }
}

public func sum(_ expression: SQLExpression) -> SQLFunction {
    .sum(expression)
}



