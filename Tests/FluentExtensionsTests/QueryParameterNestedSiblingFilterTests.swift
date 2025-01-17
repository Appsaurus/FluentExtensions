////
////  QueryParameterNestedSiblingFilterTests.swift
////
////
////  Created by Brian Strobach on 1/15/25.
////
//
//import XCTest
//import XCTVapor
//import Fluent
//import FluentSQLiteDriver
//import FluentKit
//import CodableExtensions
//import Codability
//import FluentExtensions
//@testable import FluentTestModels
//
//class QueryParameterSiblingFilterTests: FluentTestModels.TestCase {
//    
//    // Your base path for API endpoints
//    let basePath = "students"
//    
//    override func migrate(_ migrations: Migrations) throws {
//        try super.migrate(migrations)
//        migrations.add(TestStudentModelMigration())
//        migrations.add(TestClassModelMigration())
//        migrations.add(QueryParameterSiblingTestSeeder())
//    }
//    
//    override func configureTestModelDatabase(_ databases: Databases) {
//        databases.use(.sqlite(.memory, connectionPoolTimeout: .minutes(2)), as: .sqlite)
//    }
//    
//    override func addRoutes(to router: Routes) throws {
//        try super.addRoutes(to: router)
//        
//        let controller = FluentAdminController<TestStudentModel>(baseRoute: [basePath])
//        try controller.registerRoutes(routes: router)
//    }
//    
//    // Helper function to create filter URL
//    func makeFilterURL(_ condition: TestFilterCondition) throws -> String {
//        return "\(basePath)?filter=\(try condition.toURLQueryString())"
//    }
//    
//    func getFilteredItems(_ condition: TestFilterCondition) async throws -> [TestStudentModel] {
//        let response = try await app.sendRequest(.GET, try makeFilterURL(condition))
//        XCTAssertEqual(response.status, .ok)
//        return try response.content.decode(Page<TestStudentModel>.self).items
//    }
//    
//    func testNestedSiblingFilter() async throws {
//        // Test filtering students based on their classes
//        let condition = TestFilterCondition.field(
//            "classes",
//            "filter",
//            AnyCodable(try TestFilterCondition.and([
//                .field("id", "eq", TestClassModel.ID.string)
//            ]).toURLQueryString())
//        )
//        
//        let students = try await getFilteredItems(condition)
//        XCTAssertFalse(students.isEmpty)
//        // Verify that filtered students are enrolled in the specified class
//        try await students.forEach { student in
//            let classes = try await student.$classes.get(on: app.db)
//            XCTAssertTrue(classes.contains { $0.id?.uuidString == TestClassModel.ID.string })
//        }
//    }
//}
//
//// Test seeder for creating test data
//class QueryParameterSiblingTestSeeder: Migration {
//    func prepare(on database: Database) -> EventLoopFuture<Void> {
//        let class1 = TestClassModel()
//        let class2 = TestClassModel()
//        let student1 = TestStudentModel(name: "Student A")
//        let student2 = TestStudentModel(name: "Student B")
//        
//        return class1.create(on: database)
//            .and(class2.create(on: database))
//            .and(student1.create(on: database))
//            .and(student2.create(on: database))
//            .flatMap { _ in
//                let enrollment1 = TestEnrollmentModel(studentId: student1.id!, classId: class1.id!)
//                let enrollment2 = TestEnrollmentModel(studentId: student2.id!, classId: class2.id!)
//                
//                return enrollment1.create(on: database)
//                    .and(enrollment2.create(on: database))
//            }
//    }
//    
//    func revert(on database: Database) -> EventLoopFuture<Void> {
//        TestEnrollmentModel.query(on: database).delete()
//            .flatMap { TestStudentModel.query(on: database).delete() }
//            .flatMap { TestClassModel.query(on: database).delete() }
//    }
//}
//
//// End of file. No additional code.
//
