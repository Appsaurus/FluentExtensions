//
//  Model+ExtendedActions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 7/2/18.
//

import Foundation
import Fluent
import VaporExtensions
import RuntimeExtensions

public extension Model {

    @discardableResult
    func update(on database: Database, force: Bool) -> Future<Void>{
        if force {
            self._$id.exists = force
        }
        return self.update(on: database)
    }

    /// Performs an upsert with the given entity
    ///
    /// - Returns: Bool indicating whether or not the object was created. True == created, False == updated
    @discardableResult
    func upsert(on database: Database) -> Future<Void> {
        return existingEntityWithId(on: database).flatMap { model in
            guard model == nil else {
                self._$id.exists = true
                return self.update(on: database, force: true)
            }
            return self.create(on: database)
        }
    }

    func replace(with model: Future<Self>, on database: Database) -> Future<Void> {
        return delete(on: database).flatMap { model.create(on: database)}
    }

    func updateIfExists(on database: Database) -> Future<Void>{
        return assertExistingEntityWithId(on: database).flatMap { future in
            future.update(on: database, force: true)
        }
    }
}

//MARK: Returning
public extension Model {
    @discardableResult
    func upsertAndReturn(on database: Database) -> Future<Self> {
        upsert(on: database).transform(to: self)
    }

    func replaceAndReturn(with model: Future<Self>, on database: Database) -> Future<Self> {
        replace(with: model, on: database).transform(to: self)
    }

    func updateIfExistsAndReturn(on database: Database) -> Future<Self>{
        updateIfExists(on: database).transform(to: self)
    }
}

public extension Future where Value: Model{

    @discardableResult
    func upsert(on database: Database) -> Future<Void>{
        return self.flatMap { (model) in
            return model.upsert(on: database)
        }.flattenVoid()
    }

    /// Overwrites the receiver with a replacement entity
    ///
    /// - Parameter replacementEntity: The entity to be saved in place of the receiver.
    /// - Returns: The saved entity.
    @discardableResult
    func replace(with replacementEntity: Future<Value>, on database: Database) -> Future<Void>{

        return flatMap{ model in
            return model.delete(on: database).flatMap {
                return replacementEntity.save(on: database)
            }

        }.flattenVoid()
    }

    func updateIfExists(on database: Database) -> Future<Void>{
        return self.flatMap { (model) in
            return model.updateIfExists(on: database)
        }.flattenVoid()
    }
}




public extension Future where Value: Model{

    @discardableResult
    func upsertAndReturn(on database: Database) -> Future<Void>{
        return self.flatMap { (model) in
            return model.upsertAndReturn(on: database)
        }.flattenVoid()
    }

    /// Overwrites the receiver with a replacement entity
    ///
    /// - Parameter replacementEntity: The entity to be saved in place of the receiver.
    /// - Returns: The saved entity.
    @discardableResult
    func replaceAndReturn(with replacementEntity: Future<Value>, on database: Database) -> Future<Void>{

        return flatMap{ model in
            return model.delete(on: database).flatMap {
                return replacementEntity.saveAndReturn(on: database)
            }

        }.flattenVoid()
    }

    func updateIfExistsAndReturn(on database: Database) -> Future<Void>{
        return self.flatMap { (model) in
            return model.updateIfExistsAndReturn(on: database)
        }.flattenVoid()
    }
}

