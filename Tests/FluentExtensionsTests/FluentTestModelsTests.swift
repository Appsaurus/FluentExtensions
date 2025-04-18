    import XCTest
    import XCTVapor
    import Fluent
    import FluentSQLiteDriver
    import FluentKit
    @testable import FluentTestModels

    class FluentTestModelsTests: FluentTestModels.TestCase {

        override func configureTestModelDatabase(_ databases: Databases) {
            databases.use(.sqlite(.memory, connectionPoolTimeout: .minutes(2)), as: .sqlite)
        }
        
        override func addConfiguration(to app: Application) throws {
            try super.addConfiguration(to: app)
            app.logger.logLevel = .debug
        }

        
        func testKitchenSink() throws {
            let createUser = KitchenSink()
            try createUser.create(on: app.db).wait()
            let fetchedUser = try KitchenSink.query(on: app.db).first().wait()!
            XCTAssertNotNil(createUser.createdAt)
            XCTAssertNotNil(createUser.updatedAt)
            XCTAssertEqual(createUser.id, fetchedUser.id)
            XCTAssertEqual(createUser.stringField, fetchedUser.stringField)
            XCTAssertEqual(createUser.optionalStringField, fetchedUser.optionalStringField)
            XCTAssertEqual(createUser.intField, fetchedUser.intField)
            XCTAssertEqual(createUser.doubleField, fetchedUser.doubleField)
            XCTAssertEqual(createUser.booleanField, fetchedUser.booleanField)
            XCTAssertEqual(createUser.dateField.timeIntervalSince1970, fetchedUser.dateField.timeIntervalSince1970)
            XCTAssertEqual(createUser.stringArrayField, fetchedUser.stringArrayField)
            XCTAssertEqual(createUser.intArrayField, fetchedUser.intArrayField)
            XCTAssertEqual(createUser.doubleArrayField, fetchedUser.doubleArrayField)
            XCTAssertEqual(createUser.booleanArrayField, fetchedUser.booleanArrayField)
            XCTAssertEqual(createUser.dateArrayField, fetchedUser.dateArrayField)
            XCTAssertEqual(createUser.groupedFields.stringField, fetchedUser.groupedFields.stringField)
            XCTAssertEqual(createUser.groupedFields.optionalStringField, fetchedUser.groupedFields.optionalStringField)
            XCTAssertEqual(createUser.groupedFields.intField, fetchedUser.groupedFields.intField)
            XCTAssertEqual(createUser.stringEnum, fetchedUser.stringEnum)
            XCTAssertEqual(createUser.optionalStringEnum, fetchedUser.optionalStringEnum)
            XCTAssertEqual(createUser.rawStringEnum, fetchedUser.rawStringEnum)
            XCTAssertEqual(createUser.optionalRawStringEnum, fetchedUser.optionalRawStringEnum)
            XCTAssertEqual(createUser.rawIntEnum, fetchedUser.rawIntEnum)
            XCTAssertEqual(createUser.optionalRawIntEnum, fetchedUser.optionalRawIntEnum)
            XCTAssertEqual(createUser.stringEnumArray, fetchedUser.stringEnumArray)
            XCTAssertEqual(createUser.rawStringEnumArray, fetchedUser.rawStringEnumArray)
            XCTAssertEqual(createUser.rawIntEnumArray, fetchedUser.rawIntEnumArray)
            XCTAssertEqual(createUser.stringDictionary, fetchedUser.stringDictionary)
            XCTAssertEqual(createUser.intDictionary, fetchedUser.intDictionary)
            XCTAssertEqual(createUser.enumDictionary, fetchedUser.enumDictionary)
        }



        func testParentChildRelationship() throws {
            let parent = TestParentModel(name: "parent")
            try parent.create(on: app.db).wait()

            let son = try TestChildModel(name: "son", parentID: parent.requireID())
            let daughter = try TestChildModel(name: "daughter", parentID: parent.requireID())

            try son.create(on: app.db).wait()
            try daughter.create(on: app.db).wait()

//            let children = [son, daughter]
//            parent.$children.create([son, daughter], on: app.db)
            let fetchedChildren = try parent.$children.query(on: app.db).all().wait()
            let sonID = try son.requireID()
            let containsSon = fetchedChildren.contains(where: {$0.id == sonID && $0.name == son.name})
            let daughterID = try daughter.requireID()
            let containsDaughter = fetchedChildren.contains(where: {$0.id == daughterID && $0.name == daughter.name})

            XCTAssert(containsSon)
            XCTAssert(containsDaughter)

            XCTAssert(parent.$id.exists)
            XCTAssert(son.$id.exists)
            XCTAssert(daughter.$id.exists)


        }

        func testSiblings() throws {

            func assert(_ student: TestStudentModel, isEnrolled: Bool, in `class`: TestClassModel) throws {
                //Check via class
                let isInClassRoster = try `class`.$students.isAttached(to: student, on: app.db).wait()

                //Check via student
                let isOnStudentSchedule = try student.$classes.isAttached(to: `class`, on: app.db).wait()

                if isEnrolled {
                    XCTAssert(isInClassRoster)
                    XCTAssert(isOnStudentSchedule)
                }
                else {
                    XCTAssertFalse(isInClassRoster)
                    XCTAssertFalse(isOnStudentSchedule)
                }
            }

            let brian = TestStudentModel(name: "Brian")
            let josh = TestStudentModel(name: "Josh")
            let gerry = TestStudentModel(name: "Gerry")

            try [brian, josh, gerry].forEach({try $0.create(on: app.db).wait()})


            let algorithms = TestClassModel()
            let discreteMathematics = TestClassModel()

            try [algorithms, discreteMathematics].forEach({try $0.save(on: app.db).wait()})

            try algorithms.$students.attach([brian, josh], on: app.db).wait()

            try discreteMathematics.$students.attach([brian, gerry], on: app.db).wait()


            try assert(brian, isEnrolled: true, in: algorithms)
            try assert(josh, isEnrolled: true, in: algorithms)
            try assert(gerry, isEnrolled: false, in: algorithms)

            try assert(brian, isEnrolled: true, in: discreteMathematics)
            try assert(josh, isEnrolled: false, in: discreteMathematics)
            try assert(gerry, isEnrolled: true, in: discreteMathematics)


        }


        func testSelfSiblings() throws {
            let bill = TestUserModel(name: "Bill")
            try bill.create(on: app.db).wait()

            let ted = TestUserModel(name: "Ted")
            try ted.create(on: app.db).wait()

            let socrates = TestUserModel(name: "Socrates")
            try socrates.create(on: app.db).wait()
//            let socratesID = try socrates.requireID()

            try ted.$socialGraph.attach(bill, on: app.db).wait()
            try assert(bill, ted, areFriends: true)

            //Make sure we throw if we try to add an existing relationship in reverse.
            XCTAssertThrowsError(try bill.$socialGraph.attach(ted, on: app.db).wait())

            //Make sure we throw if we try to add an existing relationship by creating pivot directly.

            let friendshipModel = TestFriendshipModel()
            try friendshipModel.$fromUser.id = ted.requireID()
            try friendshipModel.$toUser.id = bill.requireID()
            XCTAssertThrowsError(try friendshipModel.create(on: app.db).wait())

            let friendshipModelReverse = TestFriendshipModel()
            try friendshipModelReverse.$fromUser.id = bill.requireID()
            try friendshipModelReverse.$toUser.id = ted.requireID()
            XCTAssertThrowsError(try friendshipModelReverse.create(on: app.db).wait())

            //Detach friendship
            try bill.$socialGraph.detach(ted, on: app.db).wait()

            try assert(bill, ted, areFriends: false)



        }

        func assert(_ fromUser: TestUserModel, _ toUser: TestUserModel, areFriends: Bool) throws {
            let fromUserID = try fromUser.requireID()
            let toUserID = try toUser.requireID()

            func assertion(_ expression: Bool) -> () {
                if areFriends {
                    XCTAssert(expression)
                }
                else {
                    XCTAssertFalse(expression)
                }
            }
            //Check these methods in both directions

            //Through isAttached(to:on:) method of socialGraph property.
            assertion(try fromUser.$socialGraph.isAttached(to: toUser, on: app.db).wait())
            assertion(try toUser.$socialGraph.isAttached(to: fromUser, on: app.db).wait())

            //Check queries to make sure they return friends.

            //Through sqlQuery(on:) method of socialGraph property.
            let toUserFriends = try toUser.$socialGraph
                .sqlQuery(on: app.db)
                .all(decoding: TestUserModel.self).wait()
            let toUserIsFriendsWithFromUser = toUserFriends.contains(where: {$0.id == fromUserID})

            assertion(toUserIsFriendsWithFromUser)


            //Fetch all friends through Fluent QueryBuilder
            let fromUserFriends = try fromUser.$socialGraph.get(reload: true, on: app.db).wait()
            let fromUserIsFriendsWithToUser = fromUserFriends.contains(where: {$0.id == toUserID})

            assertion(fromUserIsFriendsWithToUser)

            //Through query(on:) method of socialGraph property.
            let fromUserFriendQueryBuilder = try fromUser.$socialGraph.query(on: app.db).wait()
            let fromUserFilteredFriends = try fromUserFriendQueryBuilder.filter(\.$name == toUser.name).all().wait()
            assertion(fromUserFilteredFriends.contains(where: {$0.id == toUserID}))
        }
    }
