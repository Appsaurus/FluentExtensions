//
//  Model+Seeding.swift
//  
//
//  Created by Brian Strobach on 8/9/21.
//

import FluentKit
import VaporExtensions

public typealias ModelInitializer<M: Model> = () -> M
extension Model where Self: Decodable{
    @discardableResult
    static public func create(id: IDValue? = nil, on database: Database, _ initializer: ModelInitializer<Self>) -> Future<Self>{
        let model: Self = initializer()
        if let id = id {
            model.id = id
        }
        return model.createAndReturn(on: database)
    }

    @discardableResult
    static public func createSync(id: IDValue? = nil, on database: Database, _ initializer: ModelInitializer<Self>) throws -> Self{
        return try create(id: id, on: database, initializer).wait()
    }

    @discardableResult
    static public func createBatchSync(size: Int, on database: Database, _ initializer: @escaping ModelInitializer<Self>) throws -> [Self]{
        return try createBatch(size: size, on: database, initializer).wait()
    }



    @discardableResult
    static public func createBatch(size: Int, on database: Database, _ initializer: @escaping ModelInitializer<Self>) -> Future<[Self]> {

        var models: [Future<Self>] = []
        if size > 0{
            for _ in 1...size{
                models.append(self.create(on: database, initializer))
            }
        }
        return models.flatten(on: database)
    }

    @discardableResult
    static public func findOrCreate(id: IDValue, on database: Database,  _ initializer: @escaping ModelInitializer<Self>) -> Future<Self>{
        return find(id, on: database).unwrapOr {
            create(id: id, on: database, initializer)
        }
    }

    @discardableResult
    static public func findOrCreateBatch(ids: [IDValue], on database: Database, _ initializer: @escaping ModelInitializer<Self>) -> Future<[Self]>{
        var models: [Future<Self>] = []
        for id in ids{
            models.append(self.findOrCreate(id: id, on: database, initializer))
        }
        return models.flatten(on: database)
    }

    @discardableResult
    static public func findOrCreateSync(id: IDValue, on database: Database, _ initializer: @escaping ModelInitializer<Self>) throws -> Self{
        let futureModel: Future<Self> = findOrCreate(id: id, on: database, initializer)
        let model: Self = try futureModel.wait()
        return model
    }

    @discardableResult
    static public func findOrCreateBatchSync(ids: [IDValue],
                                             on database: Database,
                                             _ initializer: @escaping ModelInitializer<Self>) throws -> [Self]{
        return try findOrCreateBatch(ids: ids, on: database, initializer).wait()
    }
}

public extension Future where Value: Vapor.OptionalType {
    /// Unwraps an optional value contained inside a Future's expectation.
    /// If the optional resolves to `nil` (`.none`), the supplied error will be thrown instead.
    func unwrapOr(or resolve: @escaping () -> Future<Value.WrappedType>) -> Future<Value.WrappedType> {
        return flatMap { optional in
            guard let _ = optional.wrapped else {
                return resolve()
            }
            return self.unwrap(or: Abort(.internalServerError))
        }
    }
}
