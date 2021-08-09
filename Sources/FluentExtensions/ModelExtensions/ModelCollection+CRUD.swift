//
//  Model+CollectionCRUD.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 7/2/18.
//

import Foundation
import Fluent
import Vapor

extension Collection where Element: Model {

	public func create(on conn: Database, transaction: Bool) -> Future<Void> {
		return performBatch(action: create, on: conn, transaction: transaction)
	}

	public func save(on conn: Database, transaction: Bool) -> Future<Void>{
		return performBatch(action: save, on: conn, transaction: transaction)
	}

	public func update(on conn: Database, transaction: Bool) -> Future<Void>{
		return performBatch(action: update, on: conn, transaction: transaction)
	}

    public func delete(force: Bool = false, on conn: Database, transaction: Bool) -> Future<Void> {
        performBatch(action: { database in
            delete(force: force, on: conn)
        }, on: conn, transaction: transaction)

    }


    public func createAndReturn(on conn: Database, transaction: Bool) -> Future<Self> {
        return performBatch(action: createAndReturn, on: conn, transaction: transaction)
    }

    public func saveAndReturn(on conn: Database, transaction: Bool) -> Future<Self>{
        return performBatch(action: saveAndReturn, on: conn, transaction: transaction)
    }

    public func updateAndReturn(on conn: Database, transaction: Bool) -> Future<Self>{
        return performBatch(action: updateAndReturn, on: conn, transaction: transaction)
    }
}


extension Future where Value: Collection, Value.Element: Model{

	public func create(on conn: Database, transaction: Bool) -> Future<Void>{
		return flatMap { elements in
			return elements.create(on: conn)
		}
	}

//	public func delete(on conn: Database) -> Future<Void>{
//		return flatMap(to: Void.self) { elements in
//			return elements.delete(on: conn)
//		}
//	}

	public func save(on conn: Database, transaction: Bool) -> Future<Void>{
        return flatMap { $0.save(on: conn, transaction: transaction )}
	}

	public func update(on conn: Database, transaction: Bool) -> Future<Void>{
        return flatMap { $0.update(on: conn, transaction: transaction )}
	}

    public func createAndReturn(on conn: Database, transaction: Bool) -> Future<Value> {

        return flatMap { $0.createAndReturn(on: conn, transaction: transaction )}
    }


    public func delete(force: Bool = false, on conn: Database, transaction: Bool) -> Future<Void> {
        return flatMap { $0.delete(force: force, on: conn, transaction: transaction )}

    }

    public func saveAndReturn(on conn: Database, transaction: Bool) -> Future<Value>{
        return flatMap { $0.saveAndReturn(on: conn, transaction: transaction )}
    }

    public func updateAndReturn(on conn: Database, transaction: Bool) -> Future<Value>{
        return flatMap { $0.updateAndReturn(on: conn, transaction: transaction )}
    }
}
