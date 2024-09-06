//
//  FluentAdminControllerPivotTests.swift
//  
//
//  Created by Brian Strobach on 9/4/24.
//

import XCTest
import FluentExtensions
@testable import FluentTestModels

class FluentAdminControllerPivotTests: FluentAdminControllerTestCase {
    let basePath = "classes"
    
    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)
        
        let controller = FluentAdminController<TestClassModel>(baseRoute: [basePath])
        try controller.registerRoutes(routes: router)
        controller.pivotCRUDRoutes(router.grouped(basePath),
                                   relationshipName: "enrollments",
                                   through: \.$students,
                                   pivotController: FluentAdminController<TestEnrollmentModel>())
    }
    
    func testGetPivots() throws {
        try app.test(.GET, "\(basePath)/\(Self.classUUID)/pivots/enrollments") { response in
            XCTAssertEqual(response.status, .ok)
            let pivots = try response.content.decode([TestEnrollmentModel].self)
            XCTAssertFalse(pivots.isEmpty)
            XCTAssertEqual(pivots.first?.$class.id, Self.classUUID)
            XCTAssertEqual(pivots.first?.$student.id, Self.student1UUID)
        }
    }
    
    func testReplacePivots() throws {
        let newPivot = TestEnrollmentModel()
        newPivot.$class.id = Self.classUUID
        newPivot.$student.id = Self.student1UUID
        
        try app.test(.PUT, "\(basePath)/\(Self.classUUID)/pivots/enrollments", beforeRequest: { req in
            try req.content.encode([newPivot])
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let updatedPivots = try response.content.decode([TestEnrollmentModel].self)
            XCTAssertEqual(updatedPivots.count, 1)
            XCTAssertEqual(updatedPivots.first?.$class.id, Self.classUUID)
            XCTAssertEqual(updatedPivots.first?.$student.id, Self.student1UUID)
        })
        
    }
    
    func testAttachPivot() async throws {

        let newPivot = TestEnrollmentModel()
        newPivot.id = UUID()
        newPivot.$class.id = Self.classUUID
        newPivot.$student.id = Self.student2UUID
        try app.test(.PUT, "\(basePath)/\(Self.classUUID)/pivots/enrollments/attach", beforeRequest: { req in
            try req.content.encode([newPivot])
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        
        // Verify the pivot was attached
        try app.test(.GET, "\(basePath)/\(Self.classUUID)/pivots/enrollments") { response in
            XCTAssertEqual(response.status, .ok)
            let pivots = try response.content.decode([TestEnrollmentModel].self)
            XCTAssertEqual(pivots.count, 2) // Original + new pivot
            XCTAssertEqual(try pivots[1].requireID(), try newPivot.requireID())
        }
    }
    
    func testDetachPivot() throws {
        throw XCTSkip()
        let pivotToDetach = TestEnrollmentModel()
        pivotToDetach.$class.id = Self.classUUID
        pivotToDetach.$student.id = Self.student1UUID
        
        try app.test(.PUT, "\(basePath)/\(Self.classUUID)/pivots/enrollments/detach", beforeRequest: { req in
            try req.content.encode([pivotToDetach])
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        
        // Verify the pivot was detached
        try app.test(.GET, "\(basePath)/\(Self.classUUID)/pivots/enrollments") { response in
            XCTAssertEqual(response.status, .ok)
            let pivots = try response.content.decode([TestEnrollmentModel].self)
            XCTAssertTrue(pivots.isEmpty)
        }
    }
}
