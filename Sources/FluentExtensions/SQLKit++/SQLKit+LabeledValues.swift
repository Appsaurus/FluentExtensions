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

public typealias LabeledCount = LabeledValue<Int>

public extension SQLSelectBuilder {
    func countGroupedBy<M: Model, V: QueryableProperty>(_ keyPath: KeyPath<M, V>) async throws -> [String: Int] {
        let labeledCounts = try await labeledCountsGroupedBy(keyPath)
        return labeledCounts.asDictionary
    }

    func labeledCountsGroupedBy<M: Model, V: QueryableProperty>(
        _ keyPath: KeyPath<M, V>,
        defaultValue: SQLExpression? = nil
    ) async throws -> [LabeledCount] {
        try await labeledCountOfValues(groupedBy: keyPath, defaultValue: defaultValue)
            .all(decoding: LabeledCount.self)
    }
    
    func labeledCountOfValues<M: Model, V: QueryableProperty>(
        groupedBy keyPath: KeyPath<M, V>,
        label: String? = nil,
        valueLabel: String? = nil,
        defaultValue: SQLExpression? = nil
    ) -> SQLSelectBuilder {
        return self.labeledCountOfValues(
            groupedBy: keyPath,
            of: M.schemaOrAlias,
            label: label,
            valueLabel: valueLabel,
            defaultValue: defaultValue
        )
    }

    func labeledCountOfValues(
        groupedBy keyPath: SQLExpression,
        of table: String,
        label: String? = nil,
        valueLabel: String? = nil,
        defaultValue: SQLExpression? = nil
    ) -> SQLSelectBuilder {
        return self
            .column(COALESCE(keyPath, defaultValue ?? SQLLiteral.string("Unknown")).cast(as: .text).as(label ?? "label"))
            .columns(COUNT().as(valueLabel ?? "value"))
            .from(table)
            .groupBy(keyPath)
    }
}

extension SQLSelectBuilder {
    public func groupByRollup(_ args: SQLExpression...) -> Self {
        return groupBy(SQLFunction("ROLLUP", args: args))
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
