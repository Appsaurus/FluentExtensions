//
//  FluentAdminControllerChildrenTests.swift
//  
//
//  Created by Brian Strobach on 9/4/24.
//

import XCTest
import FluentExtensions
@testable import FluentTestModels

class FluentAdminControllerChildrenTests: FluentAdminControllerTestCase {
    let basePath = "parents"
    
    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)
        
        let controller = FluentAdminController<TestParentModel>(baseRoute: [basePath])
        try controller.registerRoutes(routes: router)
        let baseRouter = router.grouped(basePath)
        controller.childCRUDRoute(baseRouter,
                                  childForeignKeyPath: \.$children,
                                  childController: FluentAdminController<TestChildModel>())
        controller.childCRUDRoute(baseRouter,
                                  childForeignKeyPath: \.$optionalChildren,
                                  childController: FluentAdminController<TestChildModel>())
    }
    
    func testAttachChildren() throws {
        
        try app.test(.PUT, "\(basePath)/\(Self.parentUUID)/children/parentID/attach", beforeRequest: { req in
            try req.content.encode([self.child2])
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        
        // Verify the child was attached
        try app.test(.GET, "\(basePath)/\(Self.parentUUID)/children/parentID") { response in
            XCTAssertEqual(response.status, .ok)
            let children = try response.content.decode([TestChildModel].self)
            XCTAssertTrue(children.contains { $0.id == Self.child2UUID })
        }
    }
    
    func testDetachChildren() async throws {
                
        
        var response = try app.testPut("\(basePath)/\(Self.parentUUID)/children/parentID/detach", 
                                       body: [self.child1])
        XCTAssertEqual(response.status, .badRequest) //Parent ID is required, cannot detach
        
        
        // Verify the child1 is currently attached to parent2
        response = try app.test(.GET, "\(basePath)/\(Self.parent2UUID)/children/optionalParentID")
        XCTAssertEqual(response.status, .ok)
        var children = try response.content.decode([TestChildModel].self)
        XCTAssertTrue(children.contains { $0.id == Self.child1UUID })
        
        response = try  app.testPut("\(basePath)/\(Self.parent2UUID)/children/optionalParentID/detach",
                                    body: [self.child1])
        
        XCTAssertEqual(response.status, .ok)
        
        // Verify the child was detached
        response = try app.test(.GET, "\(basePath)/\(Self.parent2UUID)/children/optionalParentID")
        XCTAssertEqual(response.status, .ok)
        children = try response.content.decode([TestChildModel].self)
        XCTAssertFalse(children.contains { $0.id == Self.child1UUID })
    }
    
    func testReplaceChildren() throws {
        let optionalParentPath = "\(basePath)/\(Self.parentUUID)/children/optionalParentID"
        var response = try app.testPut(optionalParentPath, body: [self.child1, self.child2, self.child3])
        XCTAssertEqual(response.status, .ok)
        
        response = try app.test(.GET, optionalParentPath)
        XCTAssertEqual(response.status, .ok)
        var children = try response.content.decode([TestChildModel].self)
        XCTAssert(children.contains { $0.id == Self.child1UUID })
        XCTAssert(children.contains { $0.id == Self.child2UUID })
        XCTAssert(children.contains { $0.id == Self.child3UUID })
        
        
        response = try app.testPut(optionalParentPath, body: [] as [TestChildModel])
        XCTAssertEqual(response.status, .ok)
        children = try response.content.decode([TestChildModel].self)
        XCTAssertTrue(children.length == 0)
        
        response = try app.testPut(optionalParentPath, body: [self.child1])
        
        XCTAssertEqual(response.status, .ok)
        children = try response.content.decode([TestChildModel].self)
        XCTAssertTrue(children.length == 1)
        XCTAssert(children.contains { $0.id == Self.child1UUID })

    }
}
