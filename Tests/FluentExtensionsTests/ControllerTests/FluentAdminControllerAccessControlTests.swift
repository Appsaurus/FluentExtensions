//
//  File.swift
//
//
//  Created by Brian Strobach on 2/4/25.
//

import XCTest
import FluentExtensions
@testable import FluentTestModels

class FluentAdminControllerAccessControlTests: FluentAdminControllerTestCase {
    let basePath = "classes"
    var controller = FluentAdminController<TestClassModel>()
    
    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)
        
        // Initialize controller with access control configuration
        let config = FluentAdminController<TestClassModel>.Config(baseRoute: [basePath])
        config.accessControl.resource[.read] = { req, resource in
            // Simulate a resource that requires authorization
            return false
        }
        
        config.accessControl.resource[.update] = { req, resource in
            // Simulate a conditional access control
            return resource.id == Self.classUUID
        }
        
        config.accessControl.resources[.create] = { req, resources in
            // Simulate batch operation access control
            return resources.count <= 5
        }
        
        controller.config = config
        try controller.registerRoutes(routes: router)
    }
    
    func testUnauthorizedRead() throws {
        try app.test(.GET, "\(basePath)/\(Self.classUUID)") { response in
            XCTAssertEqual(response.status, .unauthorized)
        }
    }
    
    func testConditionalUpdateAccess() throws {
        // Should succeed for allowed ID
        let allowedUpdate = TestClassModel()
        allowedUpdate.id = Self.classUUID
        
        try app.test(.PUT, "\(basePath)/update/\(Self.classUUID)", beforeRequest: { req in
            try req.content.encode(allowedUpdate)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        
        // Should fail for different ID
        let unauthorizedUpdate = TestClassModel()
        unauthorizedUpdate.id = Self.class2UUID
        
        try app.test(.PUT, "\(basePath)/update/\(unauthorizedUpdate.id!)", beforeRequest: { req in
            try req.content.encode(unauthorizedUpdate)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
    }
    
    func testBatchCreateAccessControl() throws {
        // Test with allowed batch size
        let allowedBatch = (1...5).map { _ in TestClassModel() }
        
        try app.test(.POST, "\(basePath)/batch", beforeRequest: { req in
            try req.content.encode(allowedBatch)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        
        // Test with exceeded batch size
        let exceededBatch = (1...6).map { _ in TestClassModel() }
        
        try app.test(.POST, "\(basePath)/batch", beforeRequest: { req in
            try req.content.encode(exceededBatch)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
    }
}
