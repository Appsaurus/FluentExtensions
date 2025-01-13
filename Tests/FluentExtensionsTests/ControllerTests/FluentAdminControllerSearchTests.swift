//
//  FluentAdminControllerSearchTests.swift
//  
//
//  Created by Brian Strobach on 9/4/24.
//

import FluentExtensions
@testable import FluentTestModels

class FluentAdminControllerSearchTests: FluentAdminControllerTestCase {
    let basePath = "classes"
    
    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)
        
        let controller = FluentAdminController<TestClassModel>(baseRoute: [basePath])
        try controller.registerRoutes(routes: router)
    }
    
//    func testSearch() throws {
//        try app.test(.GET, "\(basePath)/search?name=Class") { response in
//            XCTAssertEqual(response.status, .ok)
//            let models = try response.content.decode([TestClassModel].self)
//            XCTAssertFalse(models.isEmpty)
//            XCTAssertTrue(models.allSatisfy { $0.name.contains("Class") })
//        }
//    }
}
