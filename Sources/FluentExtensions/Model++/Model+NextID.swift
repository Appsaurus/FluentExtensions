//
//  Model+NextID.swift
//
//
//  Created by Brian Strobach on 9/2/21.
//

import Fluent
import CollectionConcurrencyKit

public extension Model where IDValue == Int {
    static func nextID(on database: Database) async throws -> IDValue {
        let value = try await query(on: database).sort(\._$id, .descending).first()
        return (value?.id ?? -1) + 1
    }
}
