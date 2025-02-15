//
//  FluentAdminControllerCRUDTests.swift
//  
//
//  Created by Brian Strobach on 9/4/24.
//

import XCTest
import FluentExtensions
@testable import FluentTestModels

class FluentAdminControllerCRUDTests: FluentAdminControllerTestCase {
    let basePath = "classes"
    
    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)

        let controller = FluentAdminController<TestClassModel>(config: Controller.Config(baseRoute: [basePath]))
        try router.register(controller)
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
        try app.test(.GET, "\(basePath)/\(Self.classUUID)") { response in
            XCTAssertEqual(response.status, .ok)
            let model = try response.content.decode(TestClassModel.self)
            XCTAssertEqual(model.id, Self.classUUID)
        }
    }
    
    func testUpdate() throws {
        let updatedClass = TestClassModel()
        updatedClass.id = Self.classUUID
        
        try app.test(.PUT, "\(basePath)/update/\(Self.classUUID)", beforeRequest: { req in
            try req.content.encode(updatedClass)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let updatedModel = try response.content.decode(TestClassModel.self)
            XCTAssertEqual(updatedModel.id, Self.classUUID)
        })
    }
    
    func testSave() throws {
        let savedClass = TestClassModel()
        savedClass.id = Self.classUUID
        
        try app.test(.PUT, "\(basePath)/\(Self.classUUID)", beforeRequest: { req in
            try req.content.encode(savedClass)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let updatedModel = try response.content.decode(TestClassModel.self)
            XCTAssertEqual(savedClass.id, Self.classUUID)
        })
    }
    
    func testDelete() throws {
        try app.test(.DELETE, "\(basePath)/\(Self.classUUID)") { response in
            XCTAssertEqual(response.status, .ok)
        }
        
        try app.test(.GET, "\(basePath)/\(Self.classUUID)") { response in
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
