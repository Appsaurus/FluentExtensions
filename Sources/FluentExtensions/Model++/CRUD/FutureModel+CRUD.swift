//
//  FutureModel+CRUD.swift
//  
//
//  Created by Brian Strobach on 8/9/21.
//

import VaporExtensions
import FluentKit

public extension Future where Value: Model{

    func create(on database: Database) -> Future<Void>{
        flatMap { $0.create(on: database)}
    }

    func save(on database: Database) -> Future<Void>{
        flatMap { $0.save(on: database)}
    }

    func update(on database: Database) -> Future<Void>{
        flatMap {
            $0.update(on: database, force: true)
        }
    }

    func delete(force: Bool = false, on database: Database) -> Future<Void> {
        flatMap { $0.delete(force: force, on: database)}

    }
}
