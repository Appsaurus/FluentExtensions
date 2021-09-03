//
//  Model+ReturningCRUD.swift
//  
//
//  Created by Brian Strobach on 8/9/21.
//

import FluentKit
import VaporExtensions

public extension Model{

    func createAndReturn(on database: Database) -> Future<Self>{
        create(on: database).transform(to: self)
    }

    func saveAndReturn(on database: Database) -> Future<Self>{
        save(on: database).transform(to: self)
    }

    func updateAndReturn(on database: Database) -> Future<Self>{
        update(on: database).transform(to: self)
    }
}


public extension Future where Value: Model{

    func createAndReturn(on database: Database) -> Future<Value>{
        flatMap { $0.createAndReturn(on: database) }
    }

    func saveAndReturn(on database: Database) -> Future<Value>{
        flatMap { $0.saveAndReturn(on: database) }
    }

    func updateAndReturn(on database: Database) -> Future<Value>{
        flatMap { $0.updateAndReturn(on: database) }
    }
}


public extension Collection where Element: Model{

    func createAndReturn(on database: Database) -> Future<Self>{
        return self.create(on: database).transform(to: self)
    }

    func saveAndReturn(on database: Database) -> Future<Self>{
        return self.save(on: database).transform(to: self)
    }

    func updateAndReturn(on database: Database) -> Future<Self>{
        return self.update(on: database).transform(to: self)
    }
}
