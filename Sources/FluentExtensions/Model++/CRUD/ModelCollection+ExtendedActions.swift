import Foundation
import Fluent
import Vapor
import CollectionConcurrencyKit

public extension Collection where Element: Model {
 
    @discardableResult
    func updateBy(_ method: UpdateMethod,
                  in database: Database,
                  transaction: Bool = true) async throws -> [Element] {
        switch method {
        case .upsert:
            return try await upsert(in: database, transaction: transaction)
        case .update:
            return try await update(in: database, force: true, transaction: transaction)
        case .save:
            return try await save(in: database, transaction: transaction)
        }
    }
    
    @discardableResult
    func update(in database: Database,
                force: Bool = true,
                transaction: Bool = true) async throws -> [Element] {
        try await performBatch(
            action: { element, db in
                try await element.update(in: db, force: force)
            },
            on: database,
            transaction: transaction
        )
    }
    @discardableResult
    func upsert(in database: Database,
                transaction: Bool = true) async throws -> [Element] {
        try await performBatch(
            action: { element, db in
                try await element.upsert(in: db)
            },
            on: database,
            transaction: transaction
        )
    }


    @discardableResult
    func updateIfExists(in database: Database,
                transaction: Bool = true) async throws -> [Element] {
        try await performBatch(
            action: { element, db in
                try await element.updateIfExists(in: db)
            },
            on: database,
            transaction: transaction
        )
    }


    @discardableResult
    func replace(with models: [Element],
                 in database: Database,
                transaction: Bool = true) async throws -> [Element] {
        try await performBatch(
            action: { element, db in
                try await element.replace(with: element, on: db)
            },
            on: database,
            transaction: transaction
        )
    }
    
    @discardableResult
    func restore(on database: Database) async throws -> Self {
        guard self.count > 0 else { return self }
        
        for model in self {
            try await model.restore(on: database)
        }
        return self
    }
    
    @discardableResult
    func restore(on database: Database, transaction: Bool) async throws -> Self {
        if transaction {
            try await database.transaction { transaction in
                try await restore(on: transaction)
            }
        } else {
            try await restore(on: database)
        }
    }
}
