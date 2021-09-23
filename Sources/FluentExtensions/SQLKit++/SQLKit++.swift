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
    public var label: String
    public var value: V

    public init(label: String, value: V) {
        self.label = label
        self.value = value
    }
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


public extension SQLSelectBuilder {
    func from<M: Model>(_ modelType: M.Type) -> Self {
        return from(modelType.sqlTable)
    }
}
public extension SQLSelectBuilder {
    func countGroupedBy<M: Model, V: QueryableProperty>(_ keyPath: KeyPath<M, V>) throws -> Future<[String: Int]> {
        try labeledCountsGroupedBy(keyPath).map({$0.asDictionary})
    }

    func labeledCountsGroupedBy<M: Model, V: QueryableProperty>(_ keyPath: KeyPath<M, V>,
                                                                defaultValue: SQLExpression? = nil) throws -> Future<[LabeledCount]> {
        labeledCountOfValues(groupedBy: keyPath, defaultValue: defaultValue)
            .all(decoding: LabeledCount.self)
    }
    
    func labeledCountOfValues<M: Model, V: QueryableProperty>(groupedBy keyPath: KeyPath<M, V>,
                                                              label: String? = nil,
                                                              valueLabel: String? = nil,
                                                              defaultValue: SQLExpression? = nil) -> SQLSelectBuilder {


        return self.labeledCountOfValues(groupedBy: keyPath,
                                         of: M.schemaOrAlias,
                                         label: label,
                                         valueLabel: valueLabel,
                                         defaultValue: defaultValue)

    }

    func labeledCountOfValues(groupedBy keyPath: SQLExpression,
                              of table: SQLExpression,
                              label: String? = nil,
                              valueLabel: String? = nil,
                              defaultValue: SQLExpression? = nil) -> SQLSelectBuilder {


        return self
            .column(coalesce(keyPath, defaultValue ?? "Unknown").cast(as: "text").as(label ?? "label"))
            .columns(count(as: valueLabel ?? "value"))
            .from(table)
            .groupBy(keyPath)

    }
}



extension SQLSelectBuilder {

    //TODO: Probably need to limit this to SQL/PostgreSQL
    public func groupByRollup(_ args: SQLExpression...) -> Self {
        return groupBy(SQLFunction("ROLLUP", args: args))
//        self.select.groupBy.append(SQLFunction("ROLLUP", args: args))
    }
//    public func groupByRollup<M: Model, V: QueryableProperty>(_ keyPaths: KeyPath<M, V>...) -> Self {
//        return groupBy(SQLFunction("ROLLUP", args: keyPaths))
//    }
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
