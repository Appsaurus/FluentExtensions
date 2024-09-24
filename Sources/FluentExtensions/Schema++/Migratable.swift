//
//  Migratable.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 9/18/24.
//


import Foundation
import Vapor
import Fluent
import Runtime
import RuntimeExtensions

public protocol Migratable {
    static var migration: Migration { get }
}

public extension Migratable where Self: Model {
    static var migration: Migration {
        return AutoMigration<Self>()
    }
}

public extension Migrations {
    func add(_ model: Migratable.Type, to id: DatabaseID? = nil) {
        add(model.migration)
    }

    @inlinable
    func add(_ model: Migratable.Type..., to id: DatabaseID? = nil) {
        self.add(model, to: id)
    }

     func add(_ models: [Migratable.Type], to id: DatabaseID? = nil) {
        models.forEach { model in
            add(model, to: id)
        }
    }
}
