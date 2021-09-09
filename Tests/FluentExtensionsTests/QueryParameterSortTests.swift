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


class QueryParameterSortTestSeeder: Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        seedModels(on: database)
    }

    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture({}())
    }

    func seedModels(on database: Database) -> EventLoopFuture<Void> {
        var kitchenSinks: [KitchenSink] = []
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for (index, letter) in letters.enumerated() {
            let createUser = KitchenSink()
            createUser.stringField += "_\(letter)"
            createUser.intField = index
            createUser.optionalStringField = index < 3 ? String(letter) : nil
            kitchenSinks.append(createUser)
        }
        return kitchenSinks.create(on: database)
    }
}
class QueryParameterSortTests: FluentTestModels.TestCase {
    let queryParamSortPath = "query-parameters-sort"
    let valueA = "StringValue_A"
    let valueB = "StringValue_B"
    let valueC = "StringValue_C"

    override func configureTestModelDatabase(_ databases: Databases) {
        databases.use(.sqlite(.memory, connectionPoolTimeout: .minutes(2)), as: .sqlite)
    }

    override func addConfiguration(to app: Application) throws {
        try super.addConfiguration(to: app)
        app.logger.logLevel = .debug
    }

    override func migrate(_ migrations: Migrations) throws {
        try super.migrate(migrations)
        migrations.add(QueryParameterSortTestSeeder())
    }

    override func addRoutes(to router: Routes) throws {
        try super.addRoutes(to: router)

        router.get(queryParamSortPath, KitchenSink.parameter) { (request, model) -> EventLoopFuture<KitchenSink> in
            return request.toFuture(model)
        }
    }

    func testEqualsFieldQuery() throws {

        try app.test(.GET, "\(queryParamSortPath)?stringField=eq:\(valueA)") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            XCTAssert(models.count == 1)
            XCTAssertEqual(models[0].stringField, valueA)
        }
    }

    func testSubsetQueries() throws {
        let values = [valueA, valueB, valueC]
        try app.test(.GET, "\(queryParamSortPath)?stringField=in:\(values.joined(separator: ","))") { response in
            XCTAssertEqual(response.status, .ok)
            let models = try response.content.decode([KitchenSink].self)
            XCTAssert(models.count == 3)
            XCTAssertEqual(models[0].stringField, valueA)
            XCTAssertEqual(models[1].stringField, valueB)
            XCTAssertEqual(models[2].stringField, valueC)
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

