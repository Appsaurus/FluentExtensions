//
//  FluentTestCase.swift
//  
//
//  Created by Brian Strobach on 8/16/21.
//

import FluentKit
import XCTVaporExtensions
import Fluent


open class FluentTestCase: VaporTestCase {

    open var autoReverts: Bool {
        true
    }
    open var autoMigrates: Bool {
        true
    }

    open override func addConfiguration(to app: Application) throws {
        try super.addConfiguration(to: app)
        try configure(app.databases)
        try configure(app.databases.middleware)
        try migrate(app.migrations)
        if autoReverts { try app.autoRevert().wait() }
        if autoMigrates { try app.autoMigrate().wait() }
    }

    open func configure(_ databases: Databases) throws{}

    open func configure(_ middleware: Databases.Middleware) throws {}

    open func migrate(_ migrations: Migrations) throws {}

}

