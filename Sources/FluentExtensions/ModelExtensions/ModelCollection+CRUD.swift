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

	public func create(on database: Database, transaction: Bool) -> Future<Void> {
		return performBatch(action: create, on: database, transaction: transaction)
	}

	public func save(on database: Database, transaction: Bool) -> Future<Void>{
		return performBatch(action: save, on: database, transaction: transaction)
	}

	public func update(on database: Database, transaction: Bool) -> Future<Void>{
		return performBatch(action: update, on: database, transaction: transaction)
	}

    public func delete(force: Bool = false, on database: Database, transaction: Bool) -> Future<Void> {
        performBatch(action: { database in
            delete(force: force, on: database)
        }, on: database, transaction: transaction)

    }


    public func createAndReturn(on database: Database, transaction: Bool) -> Future<Self> {
        return performBatch(action: createAndReturn, on: database, transaction: transaction)
    }

    public func saveAndReturn(on database: Database, transaction: Bool) -> Future<Self>{
        return performBatch(action: saveAndReturn, on: database, transaction: transaction)
    }

    public func updateAndReturn(on database: Database, transaction: Bool) -> Future<Self>{
        return performBatch(action: updateAndReturn, on: database, transaction: transaction)
    }
}


extension Future where Value: Collection, Value.Element: Model{

	public func create(on database: Database, transaction: Bool) -> Future<Void>{
		return flatMap { elements in
			return elements.create(on: database)
		}
	}

//	public func delete(on database: Database) -> Future<Void>{
//		return flatMap(to: Void.self) { elements in
//			return elements.delete(on: database)
//		}
//	}

	public func save(on database: Database, transaction: Bool) -> Future<Void>{
        return flatMap { $0.save(on: database, transaction: transaction )}
	}

	public func update(on database: Database, transaction: Bool) -> Future<Void>{
        return flatMap { $0.update(on: database, transaction: transaction )}
	}

    public func createAndReturn(on database: Database, transaction: Bool) -> Future<Value> {

        return flatMap { $0.createAndReturn(on: database, transaction: transaction )}
    }


    public func delete(force: Bool = false, on database: Database, transaction: Bool) -> Future<Void> {
        return flatMap { $0.delete(force: force, on: database, transaction: transaction )}

    }

    public func saveAndReturn(on database: Database, transaction: Bool) -> Future<Value>{
        return flatMap { $0.saveAndReturn(on: database, transaction: transaction )}
    }

    public func updateAndReturn(on database: Database, transaction: Bool) -> Future<Value>{
        return flatMap { $0.updateAndReturn(on: database, transaction: transaction )}
    }
}
