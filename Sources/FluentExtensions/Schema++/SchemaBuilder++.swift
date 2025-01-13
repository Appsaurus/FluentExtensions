//
//  SchemaBuilder+IDSugar.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/27/18.
//

import Foundation
import Vapor
import Fluent

public extension SchemaBuilder {
    func intID(auto: Bool = true) -> Self {
        field(.id, .int, .identifier(auto: auto))
    }

    func stringID(auto: Bool = true) -> Self {
        field(.id, .string, .identifier(auto: auto))
    }
}
