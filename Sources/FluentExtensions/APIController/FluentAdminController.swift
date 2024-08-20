//
//  FluentAdminController.swift
//
//
//  Created by Brian Strobach on 8/16/24.
//


open class FluentAdminController<R: FluentResourceModel>: FluentController<R,R,R,R>
where R.ResolvedParameter == R.IDValue, R: Content {
    
    open override func readModel(id: R.IDValue, in db: Database) async throws -> R {
        return try await R.find(id, on: db).unwrapped(or: Abort(.notFound))
    }
    
    open override func update(model: R,
                              with updateModel: R,
                              in db: Database) async throws -> R {
        return updateModel
    }
    
    open override func convert(_ create: R) throws -> R {
        return create
    }
    
    @discardableResult
    open override func apply(_ update: R, to model: R) throws -> R {
        return update
    }
    
    open override func read(_ model: R) throws -> R {
        return model
    }
}
