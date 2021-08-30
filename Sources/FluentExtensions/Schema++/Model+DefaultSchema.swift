//
//  Model+DefaultSchemaName.swift
//  
//
//  Created by Brian Strobach on 8/30/21.
//

import Foundation

import Foundation
import Fluent

public extension Model {
    static var schema: String { "\(self)" }

    static func schema(for database: Database) -> SchemaBuilder {
        database.schema(schema)
    }
}
