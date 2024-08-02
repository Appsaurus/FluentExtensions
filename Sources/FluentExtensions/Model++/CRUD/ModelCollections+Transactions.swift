import FluentKit
import CollectionConcurrencyKit

public typealias AsyncBatchAction<V, R> = (Database, V) async throws -> R

public extension Collection where Element: Model {
    
    func performBatch(
        action: @escaping AsyncBatchAction<Element, Element>,
        on database: Database,
        transaction: Bool = true,
        concurrently: Bool = true
    ) async throws -> [Element] {
        let batchOperation = {
            if concurrently {
                return try await self.concurrentMap { element in
                    try await action(database, element)
                }
            } else {
                return try await self.asyncMap { element in
                    try await action(database, element)
                }
            }
        }
        
        if transaction {
            return try await database.transaction { db in
                try await batchOperation()
            }
        } else {
            return try await batchOperation()
        }
    }
    
    func performBatchVoid(
        action: @escaping AsyncBatchAction<Element, Void>,
        on database: Database,
        transaction: Bool = true,
        concurrently: Bool = true
    ) async throws -> Void {
        let batchOperation = {
            if concurrently {
                try await self.concurrentForEach { element in
                    _ = try await action(database, element)
                }
            } else {
                try await asyncForEach { element in
                    _ = try await action(database, element)
                }
            }
        }
        
        if transaction {
            try await database.transaction { db in
                try await batchOperation()
            }
        } else {
            try await batchOperation()
        }
    }
}
