import XCTest
import XCTVapor
import Fluent
import FluentSQLiteDriver
import FluentKit
import CodableExtensions
import FluentExtensions
@testable import FluentTestModels

class FluentAdminControllerTestCase: FluentTestModels.TestCase {
    static let parentUUID = UUID()
    static let parent2UUID = UUID()
    static let parent3UUID = UUID()
    
    static let child1UUID = UUID()
    static let child2UUID = UUID()
    
    static let classUUID = UUID()
    
    static let student1UUID = UUID()
    static let student2UUID = UUID()
    
    var parent = TestParentModel(id: parentUUID, name: "Parent 1")
    var parent2 = TestParentModel(id: parent2UUID, name: "Parent 2")
    var parent3 = TestParentModel(id: parent3UUID, name: "Parent 3")

    var child1 = TestChildModel(id: child1UUID, name: "Child 1", parentID: parentUUID, optionalParentID: parent2UUID)
    var child2 = TestChildModel(id: child2UUID, name: "Child 2", parentID: parent2UUID)
    
    var class1 = TestClassModel(id: classUUID)
    
    var student1 = TestStudentModel(id: student1UUID, name: "Student 1")
    var student2 = TestStudentModel(id: student2UUID, name: "Student 2")

    override func migrate(_ migrations: Migrations) throws {
        try super.migrate(migrations)
        migrations.add(TestDataSeeder(testCase: self))
    }
    
    override func configureTestModelDatabase(_ databases: Databases) {
        databases.use(.sqlite(.memory, connectionPoolTimeout: .minutes(2)), as: .sqlite)
    }

    class TestDataSeeder: AsyncMigration, @unchecked Sendable {
        unowned let testCase: FluentAdminControllerTestCase

        init(testCase: FluentAdminControllerTestCase) {
            self.testCase = testCase
        }

        func prepare(on database: Database) async throws {

            testCase.parent = try await testCase.parent.save(in: database)
            testCase.parent2 = try await testCase.parent2.save(in: database)
            testCase.parent3 = try await testCase.parent3.save(in: database)
            
            testCase.child1 = try await testCase.child1.save(in: database)
            testCase.child2 = try await testCase.child2.save(in: database)
            
            testCase.class1 = try await testCase.class1.save(in: database)
                        
            testCase.student1 = try await testCase.student1.save(in: database)
            testCase.student2 = try await testCase.student2.save(in: database)
            
            let enrollment = TestEnrollmentModel()
            enrollment.$class.id = try testCase.class1.requireID()
            enrollment.$student.id = try testCase.student1.requireID()
            try await enrollment.save(in: database)                        
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
