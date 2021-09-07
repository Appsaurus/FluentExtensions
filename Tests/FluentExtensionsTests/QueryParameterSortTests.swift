//
//  QueryParameterSortTests.swift
//  
//
//  Created by Brian Strobach on 9/7/21.
//

import XCTest
import XCTVapor
import Fluent
import FluentSQLiteDriver
import FluentKit
@testable import FluentTestModels

class QueryParameterSortTests: FluentTestModels.TestCase {

    override func configureTestModelDatabase(_ databases: Databases) {
        databases.use(.sqlite(.memory, connectionPoolTimeout: .minutes(2)), as: .sqlite)
    }

    override func addConfiguration(to app: Application) throws {
        try super.addConfiguration(to: app)
        app.logger.logLevel = .debug
    }

    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)

        router.get("query-parameters-sort") { request -> EventLoopFuture<[KitchenSink]> in
            var query = KitchenSink.query(on: request.db)

//            guard let filter = try request.queryParameterFilter(name: "stringProperty") else {
//                return request.fail(with: Abort(.badRequest))
//            }
            let response = try query.filterByQueryParameters(request: request).all()
            return response
        }
    }

    func testKitchenSink() throws {
        var kitchenSinks: [KitchenSink] = []
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for (index, letter) in letters.enumerated() {
            let createUser = KitchenSink()
            createUser.stringField += "_\(letter)"
            createUser.intField = index
            createUser.optionalStringField = Bool.random() ? String(letter) : nil
            kitchenSinks.append(createUser)
        }
        try kitchenSinks.create(on: app.db).wait()

        let fetchedModels = try KitchenSink.query(on: app.db).all().wait()

        try app.test(.GET, "query-parameters-sort?stringField=eq:stringField_A") { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssert(response.has(content: "is super easy"))
        }
    }

//    func applyFilter(for property: PropertyInfo, to query: QueryBuilder<M.Database, M>, on request: Request) throws {
//        let parameter: String = property.name
//        if let queryFilter = try? request.stringKeyPathFilter(for: property.name, at: parameter) {
//            let _ = try? query.filter(queryFilter)
////            if property.type == Bool.self {
////                let _ = try? query.filterAsBool(queryFilter)
////            }
////            else  {
////                let _ = try? query.filter(queryFilter)
////            }
//        }
//    }
}

