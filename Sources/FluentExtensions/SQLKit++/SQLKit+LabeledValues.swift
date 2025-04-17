import SQLKit
import Fluent
import FluentSQL

/// A generic structure that pairs a string label with a codable value.
/// Commonly used for database query results that need both a descriptive label and an associated value.
public struct LabeledValue<V: Codable>: Codable {
    /// The descriptive label for the value
    public var label: String
    /// The associated value of type V
    public var value: V

    /// Creates a new labeled value pair.
    /// - Parameters:
    ///   - label: A string describing or identifying the value
    ///   - value: The actual value to be stored
    public init(label: String, value: V) {
        self.label = label
        self.value = value
    }
}

/// A specialized type of LabeledValue specifically for count operations
public typealias LabeledCount = LabeledValue<Int>

public extension SQLSelectBuilder {
    /// Performs a COUNT operation grouped by a specific model property and returns results as a dictionary.
    /// - Parameter keyPath: The property to group by
    /// - Returns: A dictionary mapping group labels to their counts
    func countGroupedBy<M: Model, V: QueryableProperty>(_ keyPath: KeyPath<M, V>) async throws -> [String: Int] {
        let labeledCounts = try await labeledCountsGroupedBy(keyPath)
        return labeledCounts.asDictionary
    }

    /// Returns an array of LabeledCount objects representing counts grouped by a model property.
    /// - Parameters:
    ///   - keyPath: The property to group by
    ///   - defaultValue: Optional default value for NULL cases
    /// - Returns: Array of LabeledCount objects containing group labels and their counts
    func labeledCountsGroupedBy<M: Model, V: QueryableProperty>(
        _ keyPath: KeyPath<M, V>,
        defaultValue: SQLExpression? = nil
    ) async throws -> [LabeledCount] {
        try await labeledCountOfValues(groupedBy: keyPath, defaultValue: defaultValue)
            .all(decoding: LabeledCount.self)
    }
    
    /// Configures the SQL query for counting values grouped by a specific property.
    ///
    /// Example:
    /// ```swift
    /// // Counts users grouped by their status
    /// db.select()
    ///   .labeledCountOfValues(groupedBy: \User.$status)
    ///   .all(decoding: LabeledCount.self)
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: The property to group by
    ///   - label: Optional custom name for the label column (defaults to "label")
    ///   - valueLabel: Optional custom name for the count column (defaults to "value")
    ///   - defaultValue: Optional default value for NULL cases
    /// - Returns: Configured SQLSelectBuilder for the count query
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

    /// Low-level configuration for counting values grouped by a raw SQL expression.
    /// - Parameters:
    ///   - keyPath: Raw SQL expression to group by
    ///   - table: The table name or alias
    ///   - label: Optional custom name for the label column
    ///   - valueLabel: Optional custom name for the count column
    ///   - defaultValue: Optional default value for NULL cases
    /// - Returns: Configured SQLSelectBuilder for the count query
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
    /// Adds a ROLLUP operation to the GROUP BY clause.
    /// ROLLUP generates multiple grouping sets useful for generating subtotals and totals.
    public func groupByRollup(_ args: SQLExpression...) -> Self {
        return groupBy(SQLFunction("ROLLUP", args: args))
    }
}

public extension Collection where Element == LabeledCount {
    /// Converts an array of LabeledCount objects into a dictionary mapping labels to their counts.
    var asDictionary: [String: Int] {
        var dict: [String: Int] = [:]
        for item in self {
            dict[item.label] = item.value
        }
        return dict
    }
}
