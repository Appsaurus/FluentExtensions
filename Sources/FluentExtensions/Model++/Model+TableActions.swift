//
//  Model+TableActions.swift
//  
//
//  Created by Brian Strobach on 9/2/21.
//

import Fluent
import VaporExtensions

//MARK: Destructive
public extension Model {
    /// Deletes all rows in a table
    @discardableResult
    static func delete(force: Bool = false, on database: Database, transaction: Bool = true) -> Future<Void> {
        return query(on: database).all().delete(force: force, on: database, transaction: transaction)
    }

    @discardableResult
    static func updateAll(on database: Database, transaction: Bool = true) -> Future<[Self]> {
        return query(on: database).all().updateAndReturn(on: database, transaction: transaction)
    }

    @discardableResult
    static func updateAll(on database: Database,
                       transaction: Bool = true,
                       modifications: @escaping (Self) -> Self) -> Future<[Self]> {
        return query(on: database).all().transformEach(modifications).updateAndReturn(on: database, transaction: transaction)
    }

    @discardableResult
    static func updateAllThrowingAsync(on database: Database,
                                       transaction: Bool = true,
                                       modifications: @escaping (Self) -> Future<Self>) -> Future<[Self]> {
        return query(on: database).all().flatMapEach(on: database.eventLoop, modifications).updateAndReturn(on: database, transaction: transaction)
    }

    @discardableResult
    static func updateAllAsync(on database: Database,
                               transaction: Bool = true,
                               modifications: @escaping (Self) -> Future<Self>) -> Future<[Self]> {
        return query(on: database).all().flatMapEach(on: database.eventLoop, modifications).updateAndReturn(on: database, transaction: transaction)
    }

    //Optionally return those you want updated
    @discardableResult
    static func updateAllSelectively(on database: Database,
                       transaction: Bool = true,
                       modifications: @escaping (Self) -> Self?) -> Future<[Self]> {
        return query(on: database).all().transformEach(modifications).updateAndReturn(on: database, transaction: transaction)
    }

    @discardableResult
    static func updateAllSelectivelyThrowingAsync(on database: Database,
                                       transaction: Bool = true,
                                       continueOnError: Bool = false,
                                       modifications: @escaping (Self) -> Future<Self?>) throws -> Future<[Self]> {
        let updates = query(on: database).all()
            .flatMapEach(on: database.eventLoop, modifications, continueOnError: continueOnError)
            .map({ return $0.removeNils()})
        return updates.updateAndReturn(on: database, transaction: transaction)
    }

    @discardableResult
    static func updateAllSelectivelyAsync(on database: Database,
                               transaction: Bool = true,
                               modifications: @escaping (Self) -> Future<Self?>) throws -> Future<[Self]> {
        let updates = query(on: database).all().flatMapEach(on: database.eventLoop, modifications).map({ return $0.removeNils()})
        return updates.updateAndReturn(on: database, transaction: transaction)
    }
}


// MARK: Removing nils
fileprivate protocol OptionalType {
    associatedtype Wrapped
    func map<U>(_ f: (Wrapped) throws -> U) rethrows -> U?
}

extension Optional: OptionalType {}

fileprivate extension Sequence where Iterator.Element: OptionalType {
    func removeNils() -> [Iterator.Element.Wrapped] {
        var result: [Iterator.Element.Wrapped] = []
        for element in self {
            if let element = element.map({ $0 }) {
                result.append(element)
            }
        }
        return result
    }
}
