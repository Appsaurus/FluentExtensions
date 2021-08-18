//
//  FluentTestCase.swift
//  
//
//  Created by Brian Strobach on 8/16/21.
//

import FluentKit
import VaporTestUtils
import Fluent


open class FluentTestCase: VaporTestCase {

    override open func setUp() {
        super.setUp()
        try! app.autoRevert().wait()
        try! app.autoMigrate().wait()

    }


    open override func addConfiguration(to app: Application) throws {
        try configure(app.databases)
        try configure(app.databases.middleware)
        try migrate(app.migrations)
        try super.addConfiguration(to: app)
    }

    open func configure(_ databases: Databases) throws{}

    open func configure(_ middleware: Databases.Middleware) throws {}

    open func migrate(_ migrations: Migrations) throws {}

}

