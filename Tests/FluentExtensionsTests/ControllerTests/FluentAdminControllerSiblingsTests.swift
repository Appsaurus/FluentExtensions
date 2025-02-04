//
//  FluentAdminControllerSiblingsTests.swift
//  
//
//  Created by Brian Strobach on 9/4/24.
//

import XCTest
import FluentExtensions
@testable import FluentTestModels

class FluentAdminControllerSiblingsTests: FluentAdminControllerTestCase {
    let basePath = "classes"
    
    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)
        
        let controller = FluentAdminController<TestClassModel>(config: Controller.Config(baseRoute: [basePath]))
        try controller.registerRoutes(routes: router)
        controller.siblingCRUDRoutes(router.grouped(basePath),
                                     relationshipName: "students",
                                     through: \.$students,
                                     siblingController: FluentAdminController<TestStudentModel>())
    }
    
    func testReplaceStudents() throws {
        throw XCTSkip()
        let newStudents = [
            TestStudentModel(id: UUID(), name: "New Student 1"),
            TestStudentModel(id: UUID(), name: "New Student 2")
        ]
        
        try app.test(.PUT, "\(basePath)/\(Self.classUUID)/siblings/students", beforeRequest: { req in
            try req.content.encode(newStudents)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let updatedStudents = try response.content.decode([TestStudentModel].self)
            XCTAssertEqual(updatedStudents.count, newStudents.count)
            XCTAssertTrue(updatedStudents.contains { $0.name == "New Student 1" })
            XCTAssertTrue(updatedStudents.contains { $0.name == "New Student 2" })
        })
    }
    
    func testAttachStudents() async throws {
        
        
        var response = try app.testPut("\(basePath)/\(Self.classUUID)/siblings/students/attach",
                                       body: [student2])
        
        XCTAssertEqual(response.status, .ok)
        
        // Verify the student was attached
        response = try await app.sendRequest(.GET, "\(basePath)/\(Self.classUUID)/siblings/students")
        
        XCTAssertEqual(response.status, .ok)
        let students = try response.content.decode([TestStudentModel].self)
        XCTAssertTrue(students.contains { $0.id == Self.student2UUID })
    }
    
    func testDetachStudents() throws {
        throw XCTSkip()
        try app.test(.PUT, "\(basePath)/\(Self.classUUID)/siblings/students/detach", beforeRequest: { req in
            try req.content.encode([TestStudentModel(id: Self.student1UUID, name: "Student")])
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        
        // Verify the student was detached
        try app.test(.GET, "\(basePath)/\(Self.classUUID)/siblings/students") { response in
            XCTAssertEqual(response.status, .ok)
            let students = try response.content.decode([TestStudentModel].self)
            XCTAssertFalse(students.contains { $0.id == Self.student1UUID })
        }
    }
}
