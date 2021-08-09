//
//  FutureModel+CRUD.swift
//  
//
//  Created by Brian Strobach on 8/9/21.
//

import FluentKit

extension Future where Value: Model{

    public func create(on conn: Database) -> Future<Void>{
        flatMap { $0.create(on: conn)}
    }

    public func save(on conn: Database) -> Future<Void>{
        flatMap { $0.save(on: conn)}
    }

    public func update(on conn: Database) -> Future<Void>{
        flatMap { $0.update(on: conn)}
    }

    public func delete(force: Bool = false, on conn: Database) -> Future<Void> {
        flatMap { $0.delete(force: force, on: conn)}

    }
}
