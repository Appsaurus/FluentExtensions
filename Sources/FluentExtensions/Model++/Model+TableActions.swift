//
//  Model+TableActions.swift
//  
//
//  Created by Brian Strobach on 9/2/21.
//

import Fluent
import VaporExtensions

// MARK: - Destructive
public extension Model {
    /// Deletes all rows in a table
    static func delete(force: Bool = false, in database: Database, transaction: Bool = true) async throws -> Void {
        let models = try await query(on: database).all()
        try await models.delete(force: force, in: database, transaction: transaction)
    }

    @discardableResult
    static func updateAll(in database: Database, transaction: Bool = true) async throws -> [Self] {
        let models = try await query(on: database).all()
        return try await models.update(in: database, transaction: transaction)
    }

    @discardableResult
    static func updateAll(
        in database: Database,
        transaction: Bool = true,
        modifications: @escaping (Self) -> Self
    ) async throws -> [Self] {
        let models = try await query(on: database).all()
        let modifiedModels = models.map(modifications)
        return try await modifiedModels.update(in: database, transaction: transaction)
    }

    @discardableResult
    static func updateAllThrowing(
        in database: Database,
        transaction: Bool = true,
        modifications: @escaping (Self) throws -> Self
    ) async throws -> [Self] {
        let models = try await query(on: database).all()
        let modifiedModels = try await withThrowingTaskGroup(of: Self.self) { group in
            for model in models {
                group.addTask {
                    try modifications(model)
                }
            }
            return try await group.reduce(into: [Self]()) { result, model in
                result.append(model)
            }
        }
        return try await modifiedModels.update(in: database, transaction: transaction)
    }

    @discardableResult
    static func updateAllAsync(
        in database: Database,
        transaction: Bool = true,
        modifications: @escaping (Self) async -> Self
    ) async throws -> [Self] {
        let models = try await query(on: database).all()
        let modifiedModels = await withTaskGroup(of: Self.self) { group in
            for model in models {
                group.addTask {
                    await modifications(model)
                }
            }
            return await group.reduce(into: [Self]()) { result, model in
                result.append(model)
            }
        }
        return try await modifiedModels.update(in: database, transaction: transaction)
    }

    @discardableResult
    static func updateAllSelectively(
        in database: Database,
        transaction: Bool = true,
        modifications: @escaping (Self) -> Self?
    ) async throws -> [Self] {
        let models = try await query(on: database).all()
        let modifiedModels = models.compactMap(modifications)
        return try await modifiedModels.update(in: database, transaction: transaction)
    }

    @discardableResult
    static func updateAllSelectivelyThrowing(
        in database: Database,
        transaction: Bool = true,
        continueOnError: Bool = false,
        modifications: @escaping (Self) throws -> Self?
    ) async throws -> [Self] {
        let models = try await query(on: database).all()
        let modifiedModels = try await withThrowingTaskGroup(of: Self?.self) { group in
            for model in models {
                group.addTask {
                    try modifications(model)
                }
            }
            return try await group.reduce(into: [Self]()) { result, model in
                if let model = model {
                    result.append(model)
                }
            }
        }
        return try await modifiedModels.update(in: database, transaction: transaction)
    }

    @discardableResult
    static func updateAllSelectivelyAsync(
        in database: Database,
        transaction: Bool = true,
        modifications: @escaping (Self) async -> Self?
    ) async throws -> [Self] {
        let models = try await query(on: database).all()
        let modifiedModels = await withTaskGroup(of: Self?.self) { group in
            for model in models {
                group.addTask {
                    await modifications(model)
                }
            }
            return await group.reduce(into: [Self]()) { result, model in
                if let model = model {
                    result.append(model)
                }
            }
        }
        return try await modifiedModels.update(in: database, transaction: transaction)
    }
}

// MARK: - Removing nils
fileprivate extension Sequence {
    func removeNils<T>() -> [T] where Element == T? {
        compactMap { $0 }
    }
}
//
//extension Optional: OptionalType {}
//
//fileprivate extension Sequence where Iterator.Element: OptionalType {
//    func removeNils() -> [Iterator.Element.Wrapped] {
//        var result: [Iterator.Element.Wrapped] = []
//        for element in self {
//            if let element = element.map({ $0 }) {
//                result.append(element)
//            }
//        }
//        return result
//    }
//}
