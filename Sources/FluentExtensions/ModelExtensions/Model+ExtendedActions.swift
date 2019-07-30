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

extension Future where T: Model{
	/// Performs an upsert with the given entity
	///
	/// - Returns: Bool indicating whether or not the object was created. True == created, False == updated
	@discardableResult
	public func upsert(on conn: DatabaseConnectable) throws -> Future<T>{
		return self.flatMap(to: T.self) { (model) in
			return try model.upsert(on: conn).transform(to: model)
		}
	}

	/// Overwrites the receiver with a replacement entity
	///
	/// - Parameter replacementEntity: The entity to be saved in place of the receiver.
	/// - Returns: The saved entity.
	@discardableResult
	public func replace(with replacementEntity: Future<T>, on conn: DatabaseConnectable) throws -> Future<T>{

		return flatMap(to: T.self){ model in
			return model.delete(on: conn).then{
				return replacementEntity.save(on: conn)
			}

		}
	}
}

extension Model where Database: QuerySupporting{

	/// Performs an upsert with the given entity
	///
	/// - Returns: Bool indicating whether or not the object was created. True == created, False == updated
	@discardableResult
	public func upsert(on conn: DatabaseConnectable) throws -> Future<Self>{
		return try existingEntityWithId(on: conn).flatMap(to: type(of: self)) { (model: Self?) in
			guard model == nil else {
				return self.save(on: conn)
			}
			return self.create(on: conn)
		}
	}

	public func replace(with model: Future<Self>, on conn: DatabaseConnectable) -> Future<Self> {
		return delete(on: conn).then({model.create(on: conn)})
	}

	public func updateIfExists(on conn: DatabaseConnectable) throws -> Future<Self>{
		return try assertExistingEntityWithId(on: conn).then({ future in
			return future.update(on: conn)
		})
	}
}

public typealias ModelInitializer<M: Model> = () throws -> M
extension Model where Self: Decodable{

    @discardableResult
    static public func create(id: Self.ID? = nil, on conn: DatabaseConnectable, _ initializer: ModelInitializer<Self>) throws -> Future<Self>{
        var model: Self = try initializer()
        if let id = id {
            model.fluentID = id
        }
        return model.create(on: conn)
    }

    @discardableResult
    static public func createSync(id: Self.ID? = nil, on conn: DatabaseConnectable, _ initializer: ModelInitializer<Self>) throws -> Self{
        return try create(id: id, on: conn, initializer).wait()
    }

    @discardableResult
    static public func createBatchSync(size: Int, on conn: DatabaseConnectable, _ initializer: @escaping ModelInitializer<Self>) throws -> [Self]{
        return try createBatch(size: size, on: conn, initializer).wait()
    }



    @discardableResult
    static public func createBatch(size: Int, on conn: DatabaseConnectable, _ initializer: @escaping ModelInitializer<Self>) throws -> Future<[Self]>{
        return Future.flatMap(on: conn, { () -> Future<[Self]> in
            var models: [Future<Self>] = []
            if size > 0{
                for _ in 1...size{
                    models.append(try self.create(on: conn, initializer))
                }
            }
            return models.flatten(on: conn)
        })
    }

    @discardableResult
    static public func findOrCreate(id: Self.ID, on conn: DatabaseConnectable,  _ initializer: @escaping ModelInitializer<Self>) throws -> Future<Self>{
        return self.find(id, on: conn).unwrap(or: { () -> EventLoopFuture<Self> in
            return try! self.create(id: id, on: conn, initializer)
        })

    }

    @discardableResult
    static public func findOrCreateBatch(ids: [Self.ID], on conn: DatabaseConnectable, _ initializer: @escaping ModelInitializer<Self>) throws -> Future<[Self]>{
        return Future.flatMap(on: conn, { () -> Future<[Self]> in
            var models: [Future<Self>] = []
            for id in ids{
                models.append(try self.findOrCreate(id: id, on: conn, initializer))
            }
            return models.flatten(on: conn)
        })
    }

    @discardableResult
    static public func findOrCreateSync(id: Self.ID, on conn: DatabaseConnectable, _ initializer: @escaping ModelInitializer<Self>) throws -> Self{
        let futureModel: Future<Self> = try findOrCreate(id: id, on: conn, initializer)
        let model: Self = try futureModel.wait()
        return model
    }

    @discardableResult
    static public func findOrCreateBatchSync(ids: [Self.ID], on conn: DatabaseConnectable, _ initializer: @escaping ModelInitializer<Self>) throws -> [Self]{
        return try findOrCreateBatch(ids: ids, on: conn, initializer).wait()
    }
}

public extension Future where Expectation: Vapor.OptionalType {
    /// Unwraps an optional value contained inside a Future's expectation.
    /// If the optional resolves to `nil` (`.none`), the supplied error will be thrown instead.
    func unwrap(or resolve: @escaping () -> Future<Expectation.WrappedType>) -> Future<Expectation.WrappedType> {
        return flatMap(to: Expectation.WrappedType.self) { optional in
            guard let _ = optional.wrapped else {
                return resolve()
            }
            return self.unwrap(or: Abort(.internalServerError))
        }
    }
}
