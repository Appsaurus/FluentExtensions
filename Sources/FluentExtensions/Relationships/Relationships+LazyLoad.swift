//
//  Relationships+LazyLoad.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 3/9/25.
//

import Fluent

public extension Relation {
    func loadIfNeeded(reload: Bool = false, on database: Database) async throws {
        if let _ = self.value, !reload {
            return
        } else {
            try await self.load(on: database).get()
        }        
    }
}
