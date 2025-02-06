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
        
        let controller = FluentAdminController<TestClassModel>(config: Controller.Config(baseRoute: [basePath]))
        try controller.registerRoutes(routes: router)
        controller.pivotCRUDRoutes(router.grouped(basePath),
                                   relationshipName: "enrollments",
                                   through: \.$students)
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
        let newPivotLaterUpdatedID = UUID()
        let newPivotLaterRemovedID = UUID()

        let newPivot = TestEnrollmentModel()
        newPivot.$class.id = Self.classUUID
        newPivot.$student.id = Self.student1UUID
        
        let newPivotLaterUpdated = TestEnrollmentModel()
        newPivotLaterUpdated.id = newPivotLaterUpdatedID
        newPivotLaterUpdated.$class.id = Self.classUUID
        newPivotLaterUpdated.$student.id = Self.student2UUID
        
        let newPivotLaterRemoved = TestEnrollmentModel()
        newPivotLaterRemoved.id = newPivotLaterRemovedID
        newPivotLaterRemoved.$class.id = Self.classUUID
        newPivotLaterRemoved.$student.id = Self.student3UUID
        
        
        // Test replacing with a list of new pivots
        try app.test(.PUT, "\(basePath)/\(Self.classUUID)/pivots/enrollments", beforeRequest: { req in
            try req.content.encode([newPivot, newPivotLaterUpdated, newPivotLaterRemoved])
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let pivots = try response.content.decode([TestEnrollmentModel].self)
            XCTAssertEqual(pivots.count, 3)
            // Verify all pivots are present and IDs are preserved
            let pivot1 = pivots.first { $0.$student.id == Self.student1UUID }
            let pivot2 = pivots.first { $0.$student.id == Self.student2UUID }
            let pivot3 = pivots.first { $0.$student.id == Self.student3UUID }
            
            XCTAssertNotNil(pivot1)
            XCTAssertNotNil(pivot2)
            XCTAssertNotNil(pivot3)
            XCTAssertEqual(pivot2?.id, newPivotLaterUpdatedID)
            XCTAssertEqual(pivot3?.id, newPivotLaterRemovedID)
        })
        
        // Test replacing with fewer pivots (should remove newPivotLaterRemoved) and update newPivotLaterUpdated
        try app.test(.PUT, "\(basePath)/\(Self.classUUID)/pivots/enrollments", beforeRequest: { req in
            try req.content.encode([newPivot, newPivotLaterRemoved]) // Only keep two pivots
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let pivots = try response.content.decode([TestEnrollmentModel].self)
            XCTAssertEqual(pivots.count, 2)
            
            // Verify specific pivots are present with correct IDs
            let pivot1 = pivots.first { $0.$student.id == Self.student1UUID }
            let pivot3 = pivots.first { $0.$student.id == Self.student3UUID }
            
            XCTAssertNotNil(pivot1)
            XCTAssertNotNil(pivot3)
            XCTAssertEqual(pivot3?.id, newPivotLaterRemovedID)
            
            // Verify removed pivot is not present
            XCTAssertFalse(pivots.contains { $0.$student.id == Self.student2UUID })
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
        let pivotToDetach = TestEnrollmentModel()
        pivotToDetach.$class.id = Self.classUUID
        pivotToDetach.$student.id = Self.student1UUID
        
        try app.test(.PUT, "\(basePath)/\(Self.classUUID)/pivots/enrollments/detach", beforeRequest: { req in
            try req.content.encode([pivotToDetach])
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest) //Relationship requires class, should fail
        })
        
        try app.test(.DELETE, "\(basePath)/\(Self.classUUID)/pivots/enrollments/detach", beforeRequest: { req in
            try req.content.encode([pivotToDetach])
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok) //Relationship requires class, should fail
        })
        
        // Verify the pivot was detached
        try app.test(.GET, "\(basePath)/\(Self.classUUID)/pivots/enrollments") { response in
            XCTAssertEqual(response.status, .ok)
            let pivots = try response.content.decode([TestEnrollmentModel].self)
            XCTAssertTrue(pivots.isEmpty)
        }
    }
}
