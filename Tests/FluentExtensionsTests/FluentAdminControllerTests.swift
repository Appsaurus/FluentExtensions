import XCTest
import XCTVapor
import Fluent
import FluentSQLiteDriver
import FluentKit
import CodableExtensions
import FluentExtensions
@testable import FluentTestModels

class FluentAdminControllerTestCase: FluentTestModels.TestCase {
    let classUUID = UUID()
    let parentUUID = UUID()
    let childUUID1 = UUID()
    let childUUID2 = UUID()
    let studentUUID = UUID()

    override func migrate(_ migrations: Migrations) throws {
        try super.migrate(migrations)
        migrations.add(TestDataSeeder(testCase: self))
    }
    
    override func configureTestModelDatabase(_ databases: Databases) {
        databases.use(.sqlite(.memory, connectionPoolTimeout: .minutes(2)), as: .sqlite)
    }

    class TestDataSeeder: AsyncMigration {
        unowned let testCase: FluentAdminControllerTestCase

        init(testCase: FluentAdminControllerTestCase) {
            self.testCase = testCase
        }

        func prepare(on database: Database) async throws {
            let parent = TestParentModel(id: testCase.parentUUID, name: "Parent")
            try await parent.save(on: database)
            
            let child1 = try TestChildModel(id: testCase.childUUID1, name: "Child 1", parent: parent)
            let child2 = try TestChildModel(id: testCase.childUUID2, name: "Child 2", parent: parent)
            try await child1.save(on: database)
            try await child2.save(on: database)
            
            let class1 = TestClassModel()
            class1.id = testCase.classUUID
            try await class1.save(on: database)
            
            let student1 = TestStudentModel()
            student1.id = testCase.studentUUID
            try await student1.save(on: database)
            
            let enrollment = TestEnrollmentModel()
            enrollment.$class.id = try class1.requireID()
            enrollment.$student.id = try student1.requireID()
            try await enrollment.save(on: database)
        }
        
        func revert(on database: Database) async throws {
            try await TestChildModel.query(on: database).delete()
            try await TestParentModel.query(on: database).delete()
            try await TestEnrollmentModel.query(on: database).delete()
            try await TestStudentModel.query(on: database).delete()
            try await TestClassModel.query(on: database).delete()
        }
    }
}

class FluentAdminControllerCRUDTests: FluentAdminControllerTestCase {
    let basePath = "classes"
    
    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)
        
        let controller = FluentAdminController<TestClassModel>(baseRoute: [basePath])
        try controller.registerRoutes(routes: router)
    }
    
    func testCreate() throws {
        let newClass = TestClassModel()
        
        try app.test(.POST, basePath, beforeRequest: { req in
            try req.content.encode(newClass)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let createdModel = try response.content.decode(TestClassModel.self)
            XCTAssertNotNil(createdModel.id)
        })
    }
    
    func testRead() throws {
        try app.test(.GET, "\(basePath)/\(classUUID)") { response in
            XCTAssertEqual(response.status, .ok)
            let model = try response.content.decode(TestClassModel.self)
            XCTAssertEqual(model.id, self.classUUID)
        }
    }
    
    func testUpdate() throws {
        let updatedClass = TestClassModel()
        updatedClass.id = classUUID
        
        try app.test(.PUT, "\(basePath)/\(classUUID)", beforeRequest: { req in
            try req.content.encode(updatedClass)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let updatedModel = try response.content.decode(TestClassModel.self)
            XCTAssertEqual(updatedModel.id, self.classUUID)
        })
    }
    
    func testDelete() throws {
        try app.test(.DELETE, "\(basePath)/\(classUUID)") { response in
            XCTAssertEqual(response.status, .ok)
        }
        
        try app.test(.GET, "\(basePath)/\(classUUID)") { response in
            XCTAssertEqual(response.status, .notFound)
        }
    }
    
    func testReadAll() throws {
        try app.test(.GET, "\(basePath)/all") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([TestClassModel].self)
            XCTAssertFalse(models.isEmpty)
        }
    }
}

class FluentAdminControllerSiblingTests: FluentAdminControllerTestCase {
    let basePath = "classes"
    
    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)
        
        let controller = FluentAdminController<TestClassModel>(baseRoute: [basePath])
        try controller.registerRoutes(routes: router)
        controller.siblingCRUDRoutes(router.grouped(basePath),
                                     relationshipName: "students",
                                     through: \.$students,
                                     siblingController: FluentAdminController<TestStudentModel>())
    }
    
    func testGetStudents() throws {
        try app.test(.GET, "\(basePath)/\(classUUID)/siblings/students") { response in
            XCTAssertEqual(response.status, .ok)
            let students = try response.content.decode([TestStudentModel].self)
            XCTAssertFalse(students.isEmpty)
            XCTAssertEqual(students.first?.id, self.studentUUID)
        }
    }
}

class FluentAdminControllerParentChildTests: FluentAdminControllerTestCase {
    let basePath = "parents"
    
    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)
        
        let controller = FluentAdminController<TestParentModel>(baseRoute: [basePath])
        try controller.registerRoutes(routes: router)
        let baseRouter = router.grouped(basePath)
        controller.childCRUDRoute(baseRouter,
                                  childForeignKeyPath: \.$children,
                                  childController: FluentAdminController<TestChildModel>())
    }
    
    func testGetChildren() throws {
        try app.test(.GET, "\(basePath)/\(parentUUID)/children/parentID") { response in
            XCTAssertEqual(response.status, .ok)
            let children = try response.content.decode([TestChildModel].self)
            XCTAssertFalse(children.isEmpty)
            XCTAssertEqual(children.count, 2)
            XCTAssertTrue(children.contains { $0.id == self.childUUID1 })
            XCTAssertTrue(children.contains { $0.id == self.childUUID2 })
        }
    }
    
    func testReplaceChildren() throws {
        let newChildren = [
            try TestChildModel(id: UUID(), name: "New Child 1", parent: TestParentModel(id: parentUUID, name: "Parent")),
            try TestChildModel(id: UUID(), name: "New Child 2", parent: TestParentModel(id: parentUUID, name: "Parent"))
        ]
        
        try app.test(.PUT, "\(basePath)/\(parentUUID)/children/parentID", beforeRequest: { req in
            try req.content.encode(newChildren)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let updatedChildren = try response.content.decode([TestChildModel].self)
            XCTAssertEqual(updatedChildren.count, newChildren.count)
            XCTAssertEqual(updatedChildren[0].name, newChildren[0].name)
            XCTAssertEqual(updatedChildren[1].name, newChildren[1].name)
        })
    }
}
