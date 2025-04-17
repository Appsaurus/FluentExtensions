//
//  QueryBuilder+DuplicateJoins.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 3/10/25.
//

/// Extension providing join deduplication capabilities for QueryBuilder
public extension QueryBuilder {
    /// Deduplicates joins in the query by removing any joins with identical schema targets
    /// - Returns: The QueryBuilder instance with deduplicated joins
    @discardableResult
    func deduplicateJoinsToSameTable() -> Self {
        self.query.joins = self.query.joins.uniqued(on: { element in
            switch element {
            case .join(let schema, _, _, _, _):
                return schema
            case .extendedJoin(let schema, _, _, _, _, _):
                return schema
            case .advancedJoin(let schema, _, _, _, _):
                return schema
            case .custom(let any):
                return "\(any)"
            }
        })
        return self
    }
    
    /// Checks if the query already includes a join to a specific schema
    /// - Parameter schema: The schema to check for existing joins
    /// - Returns: `true` if the query already contains a join to the specified schema, `false` otherwise
    func isJoined(to schema: Schema) -> Bool {
        return self.query.joins.contains(where: { join in
            switch join {
            case .join(let schema, _, _, _, _):
                return schema == schema
            case .extendedJoin(let schema, _, _, _, _, _):
                return schema == schema
            case .advancedJoin(let schema, _, _, _, _):
                return schema == schema
            default:
                return false
            }
        })
    }
}
