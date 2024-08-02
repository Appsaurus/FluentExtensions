import Vapor
import Fluent
import CollectionConcurrencyKit

public extension Collection where Element: Model {

    @discardableResult
    func create(in database: Database, transaction: Bool = true) async throws -> [Element] {
        try await performBatch(
            action: { db, element in
                try await element.create(in: db)
            },
            on: database,
            transaction: transaction
        )
    }

    @discardableResult
    func save(in database: Database, transaction: Bool = true) async throws -> [Element] {
        try await performBatch(
            action: { db, element in
                try await element.save(in: db)
            },
            on: database,
            transaction: transaction
        )
    }
    
    @discardableResult
    func update(in database: Database,
                transaction: Bool = true,
                force: Bool = true) async throws -> [Element] {
        try await performBatch(
            action: { db, element in
                try await element.update(in: db, force: force)
            },
            on: database,
            transaction: transaction
        )
    }
    
    func delete(force: Bool = false, in database: Database, transaction: Bool = true) async throws {
        try await performBatchVoid(
            action: { db, element in
                try await element.delete(force: force, on: db)
            },
            on: database,
            transaction: transaction
        )
    }
}
