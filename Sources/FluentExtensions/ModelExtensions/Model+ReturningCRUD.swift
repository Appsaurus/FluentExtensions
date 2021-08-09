//
//  Model+ReturningCRUD.swift
//  
//
//  Created by Brian Strobach on 8/9/21.
//

import FluentKit

public extension Model{

    func createAndReturn(on conn: Database) -> Future<Self>{
        create(on: conn).transform(to: self)
    }

    func saveAndReturn(on conn: Database) -> Future<Self>{
        save(on: conn).transform(to: self)
    }

    func updateAndReturn(on conn: Database) -> Future<Self>{
        update(on: conn).transform(to: self)
    }
}


public extension Future where Value: Model{

    func createAndReturn(on conn: Database) -> Future<Value>{
        flatMap { $0.createAndReturn(on: conn) }
    }

    func saveAndReturn(on conn: Database) -> Future<Value>{
        flatMap { $0.saveAndReturn(on: conn) }
    }

    func updateAndReturn(on conn: Database) -> Future<Value>{
        flatMap { $0.updateAndReturn(on: conn) }
    }
}


public extension Collection where Element: Model{

    func createAndReturn(on conn: Database) -> Future<Self>{
        return self.create(on: conn).transform(to: self)
    }

    func saveAndReturn(on conn: Database) -> Future<Self>{
        return self.save(on: conn).transform(to: self)
    }

    func updateAndReturn(on conn: Database) -> Future<Self>{
        return self.update(on: conn).transform(to: self)
    }
}
