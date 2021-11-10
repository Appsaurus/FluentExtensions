//
//  ChildrenProperty++.swift
//
//
//  Created by Brian Strobach on 12/18/17.
//

import VaporExtensions
import Fluent


public extension ChildrenProperty {
	/// Returns true if the supplied model is a child
	/// to this relationship.
	func includes(_ model: To, on database: Database) -> Future<Bool> {
        do {
            let id = try model.requireID()
            return query(on: database)
                .filter(\._$id == id)
                .first()
                .map { child in
                    return child != nil
            }
        }
        catch {
            return database.eventLoop.fail(with: error)
        }

	}

    func all(on database: Database) -> Future<[To]> {
        return query(on: database).all()
    }

//    @discardableResult
    func attach(_ children: [To], on database: Database) -> EventLoopFuture<Void> {
        guard let id = fromId else {
            fatalError("Cannot query children relation from unsaved model.")
        }
        children.forEach {
            switch self.parentKey {
            case .required(let keyPath):
                $0[keyPath: keyPath].id = id
            case .optional(let keyPath):
                $0[keyPath: keyPath].id = id
            }
        }
        return children.update(on: database)
    }


    @discardableResult
    func replace(with children: [To], on database: Database) -> EventLoopFuture<Void> {
        return self.all(on: database).flatMap { existingChildren in
            switch self.parentKey {
            case .required(_):
                return existingChildren.delete(force: true, on: database)
                    .flatMap({children.upsert(on: database)})
            case .optional(let keyPath):
                existingChildren.forEach({
                    $0[keyPath: keyPath].id = nil
                })
                //Need to use wrapped id since it may not exist yet.
                children.forEach({ $0[keyPath: keyPath].$id.value = self.fromId})
                return existingChildren.update(on: database)
                    .flatMap({children.upsert(on: database)}).future(Void())
            }
        }

    }

    func replaceAndReturn(with children: [To], on database: Database) -> EventLoopFuture<[To]> {
        replace(with: children, on: database).transform(to: children)
    }
}

public extension Model {
	/// Returns true if this model is a child
	/// to the supplied relationship.
	func isChild<M: Model>(_ children: ChildrenProperty<M, Self>, on database: Database) -> Future<Bool> {
		return children.includes(self, on: database)
	}

    @discardableResult
    func replaceChildren<C: Model>(with children: [C],
                                          through childKeyPath: ChildrenPropertyKeyPath<Self, C>,
                                          on database: Database) throws -> Future<[C]> {
        let _ = try self.requireID()
        return database.transaction { (database) -> Future<[C]> in
            let relation = self[keyPath: childKeyPath]
            return relation.replaceAndReturn(with: children, on: database)
        }
    }
}
