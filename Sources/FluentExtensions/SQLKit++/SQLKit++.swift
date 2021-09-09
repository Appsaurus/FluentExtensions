//
//  SQLKit++.swift
//  
//
//  Created by Brian Strobach on 9/9/21.
//

import SQLKit
import Fluent
import FluentSQL

public struct LabeledValue<V: Codable>: Codable {
    var label: String
    var value: V
}

public extension Collection where Element == LabeledCount {
    var asDictionary: [String: Int] {
        var dict: [String: Int] = [:]
        for item in self {
            dict[item.label] = item.value
        }
        return dict
    }
}
public typealias LabeledCount = LabeledValue<Int>


public extension SQLExpression {
    func `as`(_ alias: String) -> SQLAlias {
        SQLAlias(self, as: SQLLiteral.string(alias))
    }

    func cast(as type: String) -> SQLCast {
        return SQLCast(self, as: type)
    }
}
public extension SQLSelectBuilder {
    func labeledCountOfValues<M: Model, V: QueryableProperty>(groupedBy keyPath: KeyPath<M, V>,
                                                              label: String = "label",
                                                              valueLabel: String = "value",
                                                              defaultValue: String = "Unknown") -> SQLSelectBuilder {


        return self
            .column(coalesece(keyPath, defaultValue: defaultValue).cast(as: "text").as(label))
            .columns(count(as: valueLabel))
            .from(M.schema)
            .groupBy(keyPath.propertyName)

    }

    func count(_ args: [String] = ["*"], as label: String = "value") -> SQLExpression {
        SQLFunction("COUNT", args: args).as(label)
    }

    func coalesece<M: Model, V: QueryableProperty>(_ keyPath: KeyPath<M, V>,
                                                    defaultValue: String = "Unknown") -> SQLFunction {

        .coalesce(SQLColumn(keyPath.propertyName), SQLLiteral.string(defaultValue))
    }

    func countGroupedBy<M: Model, V: QueryableProperty>(_ keyPath: KeyPath<M, V>) throws -> Future<[String: Int]> {
        try labeledCountsGroupedBy(keyPath).map({$0.asDictionary})
    }

    func labeledCountsGroupedBy<M: Model, V: QueryableProperty>(_ keyPath: KeyPath<M, V>) throws -> Future<[LabeledCount]> {
        labeledCountOfValues(groupedBy: keyPath).all(decoding: LabeledCount.self)
    }

}




public struct SQLCast: SQLExpression {
    public var expression: SQLExpression
    public var type: SQLExpression

    public init(_ expression: SQLExpression, as type: String) {
        self.expression = expression
        self.type = SQLLiteral.string(type)
    }

    public init(_ expression: SQLExpression, as type: SQLExpression) {
        self.expression = expression
        self.type = type
    }

    public func serialize(to serializer: inout SQLSerializer) {
        serializer.write("CAST(")
        self.expression.serialize(to: &serializer)
        serializer.write(" AS ")
        self.type.serialize(to: &serializer)
        serializer.write(")")
    }
}


//extension Model {
//    static func query<T, F>(on database: Database, _ builder: @escaping (SQLDatabase) throws -> F) throws -> Future<[T]> where T: Decodable, F: SQLQueryFetcher {
//        try builder(database).all(decoding: T.self)
//    }
//
//    static func sqlQuery<T>(on database: Database, _ builder: @escaping (SQLDatabase) throws -> Future<T>) throws -> Future<T> where T: Decodable {
//        return try builder(database)
//    }
//
//    static func sqlSelect<T>(on database: Database, _ builder: @escaping (SQLSelectBuilder) throws -> Future<T>) throws -> Future<T>
//        where T: Decodable
//    {
//        return try sqlQuery(on: database, { qb in
//            return try builder(qb.select().from(self))
//        })
//    }
//
//    static func sqlSelectDistinct<T>(on database: Database, _ builder: @escaping (SQLSelectBuilder) throws -> Future<T>) throws -> Future<T>
//        where T: Decodable
//    {
//        return try sqlSelect(on: database, { sb in
//            sb.select.distinct = .distinct
//            return try builder(sb)
//        })
//    }
//}
