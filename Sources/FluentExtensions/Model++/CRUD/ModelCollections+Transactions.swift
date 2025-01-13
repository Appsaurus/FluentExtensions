import FluentKit
import CollectionConcurrencyKit

public typealias AsyncBatchAction<V, R> = (V, Database) async throws -> R

public enum FluentCommand {
    case create
    case save
    case update
    case upsert
    case delete(force: Bool)
    
    func action<Value: Model>() -> AsyncBatchAction<Value, Value> {
        return { (element: Value, database: Database) in
            switch self {
            case .create:
                return try await element.create(in: database)
            case .update:
                return try await element.update(in: database)
            case .upsert:
                return try await element.upsert(in: database)
            case .save:
                return try await element.save(in: database)
            case .delete(let force):
                return try await element.delete(from: database, force: force)
            }
        }
    }
}
extension Database {
    @discardableResult
    func performBatch<Input: Collection, Output>(
        action: @escaping AsyncBatchAction<Input.Element, Output>,
        on resources: Input,
        transaction: Bool = true,
        concurrently: Bool = true
    ) async throws -> [Output] {
        let batchOperation = { db in
            if concurrently {
                return try await resources.concurrentMap { element in
                    try await action(element, db)
                }
            } else {
                return try await resources.asyncMap { element in
                    try await action(element, db)
                }
            }
        }
        
        if transaction {
            return try await self.transaction { db in
                try await batchOperation(db)
            }
        } else {
            return try await batchOperation(self)
        }
    }
}
public extension Collection where Element: Model {
    func performBatch(
        _ command: FluentCommand,
        on database: Database,
        transaction: Bool = true,
        concurrently: Bool = true
    ) async throws -> [Element] {
        return try await performBatch(action: command.action(),
                                      on: database,
                                      transaction: transaction,
                                      concurrently: concurrently)
    }
    
    func performBatch(
        action: @escaping AsyncBatchAction<Element, Element>,
        on database: Database,
        transaction: Bool = true,
        concurrently: Bool = true
    ) async throws -> [Element] {
        return try await database.performBatch(action: action,
                                               on: self,
                                               transaction: transaction,
                                               concurrently: concurrently)
    }
    
    func performBatchVoid(
        action: @escaping AsyncBatchAction<Element, Void>,
        on database: Database,
        transaction: Bool = true,
        concurrently: Bool = true
    ) async throws -> Void {
        try await database.performBatch(action: action,
                                               on: self,
                                               transaction: transaction,
                                               concurrently: concurrently)
    }
}
