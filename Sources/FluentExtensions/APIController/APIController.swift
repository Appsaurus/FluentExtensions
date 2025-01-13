//
//  APIController.swift
//
//
//  Created by Brian Strobach on 5/21/24.
//

import Fluent
import Vapor

protocol APIController {
    associatedtype Model: APIModel
    
    var idKey: String { get }

    // Parses ID parameter from path or query param
    func getID(_: Request) throws -> Model.IDValue

    // generic crud methods
    func create(_: Model.CreateInput) async throws -> Model.CreateOutput
    func create(_: Request) async throws -> Model.CreateOutput
    
    func createAll(_: [Model.CreateInput]) async throws -> Model.CreateOutput
    func createAll(_: Request) async throws -> [Model.CreateOutput]
    func read(_: Request) async throws -> Model.ReadOutput
    func readAll(_: Request) async throws -> Page<Model.ReadOutput>
    func update(_: Request) async throws -> Model.UpdateOutput
    func updateAll(_: Request) async throws -> [Model.UpdateOutput]
    func delete(_: Request) async throws -> Model.DeleteOutput
    func deleteAll(_: Request) async throws -> [Model.DeleteOutput]
    
    // extended operations
    func find(_: Request) throws -> Model.SearchOutput
    func search(_: Request) async throws -> Page<Model.SearchOutput>
    func save(_: Request) async throws -> Model.SaveOutput
    func saveAll(_: Request) async throws -> [Model.SaveOutput]
    
    // router helper
    @discardableResult
    func setup(routes: RoutesBuilder, on endpoint: String) -> RoutesBuilder
}

