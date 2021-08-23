//
//  FluentTestModelsTestCase.swift
//  
//
//  Created by Brian Strobach on 8/17/21.
//

import FluentTestUtils
import FluentExtensions

public struct FluentTestModels {
    open class TestCase: FluentTestCase {
        override open func configure(_ databases: Databases) throws {
            try super.configure(databases)
            configureTestModelDatabase(databases)
        }

        open func configureTestModelDatabase(_ databases: Databases) {
            assertionFailure(String(describing: self) + " is abstract. You must implement " + #function)
        }
        override open func configure(_ middleware: Databases.Middleware) throws {
            try super.configure(middleware)
            let siblingsMiddleware = FriendshipModel.selfSiblingMiddleware(from: \.$fromUser, to: \.$toUser)
            middleware.use(siblingsMiddleware)
        }
        override open func migrate(_ migrations: Migrations) throws {
            try super.migrate(migrations)
            migrations.add([
                KitchenSink(),
                ParentModelMigration(),
                ChildModelMigration(),
                StudentModel(),
                ClassModel(),
                EnrollmentModel(),
                UserModelMigration(),
                FriendshipModelMigration()
            ])
        }
    }
}
