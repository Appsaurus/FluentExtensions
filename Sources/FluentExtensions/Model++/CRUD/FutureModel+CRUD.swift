//
//  FutureModel+CRUD.swift
//  
//
//  Created by Brian Strobach on 8/9/21.
//

import VaporExtensions
import FluentKit

extension Future where Value: Model{

    public func create(on database: Database) -> Future<Void>{
        flatMap { $0.create(on: database)}
    }

    public func save(on database: Database) -> Future<Void>{
        flatMap { $0.save(on: database)}
    }

    public func update(on database: Database) -> Future<Void>{
        flatMap { $0.update(on: database)}
    }

    public func delete(force: Bool = false, on database: Database) -> Future<Void> {
        flatMap { $0.delete(force: force, on: database)}

    }
}
