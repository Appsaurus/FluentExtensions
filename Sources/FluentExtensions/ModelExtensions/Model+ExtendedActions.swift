//
//  Model+ExtendedActions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 7/2/18.
//

import Foundation
import Fluent
import Vapor
import RuntimeExtensions

extension Model {

    /// Performs an upsert with the given entity
    ///
    /// - Returns: Bool indicating whether or not the object was created. True == created, False == updated
    @discardableResult
    public func upsert(on conn: Database) -> Future<Void> {
        return existingEntityWithId(on: conn).flatMap { model in
            guard model == nil else {
                return self.save(on: conn)
            }
            return self.create(on: conn)
        }
    }

    public func replace(with model: Future<Self>, on conn: Database) -> Future<Void> {
        return delete(on: conn).flatMap { model.create(on: conn)}
    }

    public func updateIfExists(on conn: Database) throws -> Future<Void>{
        return try assertExistingEntityWithId(on: conn).flatMap { future in
            future.update(on: conn)
        }
    }
}

//MARK: Returning
extension Model {
    @discardableResult
    public func upsertAndReturn(on conn: Database) -> Future<Self> {
        upsert(on: conn).transform(to: self)
    }

    public func replaceAndReturn(with model: Future<Self>, on conn: Database) -> Future<Self> {
        replace(with: model, on: conn).transform(to: self)
    }

    public func updateIfExistsAndReturn(on conn: Database) throws -> Future<Self>{
        try updateIfExists(on: conn).transform(to: self)
    }
}

extension Future where Value: Model{

    @discardableResult
    public func upsert(on conn: Database) -> Future<Void>{
        return self.flatMap { (model) in
            return model.upsert(on: conn)
        }.flattenVoid()
    }

    /// Overwrites the receiver with a replacement entity
    ///
    /// - Parameter replacementEntity: The entity to be saved in place of the receiver.
    /// - Returns: The saved entity.
    @discardableResult
    public func replace(with replacementEntity: Future<Value>, on conn: Database) -> Future<Void>{

        return flatMap{ model in
            return model.delete(on: conn).flatMap {
                return replacementEntity.save(on: conn)
            }

        }.flattenVoid()
    }

    public func updateIfExists(on conn: Database) throws -> Future<Void>{
        return self.flatMapThrowing { (model) in
            return try model.updateIfExists(on: conn)
        }.flattenVoid()
    }
}

