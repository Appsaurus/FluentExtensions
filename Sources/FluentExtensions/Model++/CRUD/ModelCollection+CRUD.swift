import Vapor
import Fluent
import CollectionConcurrencyKit

public extension Collection where Element: Model {

    @discardableResult
    func create(in database: Database, 
                transaction: Bool = true) async throws -> [Element] {
        try await performBatch(.create,
                               on: database,
                               transaction: transaction)
    }

    @discardableResult
    func save(in database: Database, 
              transaction: Bool = true) async throws -> [Element] {
        try await performBatch(.save,
                               on: database,
                               transaction: transaction)
    }
    
    @discardableResult
    func update(in database: Database,
                transaction: Bool = true) async throws -> [Element] {
        try await performBatch(.update,
                               on: database,
                               transaction: transaction)
    }
    
    @discardableResult
    func delete(from database: Database, force: Bool = false, transaction: Bool = true) async throws -> [Element]{
        try await performBatch(.delete(force: force),
                               on: database,
                               transaction: transaction
        )
    }
}
