//
//  FutureExtensions.swift
//  
//
//  Created by Brian Strobach on 4/1/18.
//

import Foundation
import Fluent
import Vapor
import CodableExtensions
import RuntimeExtensions

//TODO: Revisit this with testing
//public extension Future where Value: Collection, Value.Element: Model/* & Reflectable*/ {
//
//	func update(with request: Request) throws -> Future<Value> {
//
//		let decoder: JSONDecoder = .default
//
//		let data =  request.body.data!
//        let jsonArray: [AnyCodableDictionary] = try decoder.decode([AnyCodableDictionary].self, from: data)
//        return try update(with: jsonArray, keyedBy: Value.Element.idKeyStringPath, on: request)
//	}
//
//	func update(with json: [AnyCodableDictionary], keyedBy keyPath: String, on database: Request) throws -> Future<Value> {
//		let jsonMap: [String : AnyCodableDictionary] = try json.indexed { (dictionary) in
//			guard let id: Any = dictionary[keyPath] else { throw Abort(.badRequest) }
//			return "\(id)"
//		}
//
//
//        return flatMapThrowing { (models: Value) throws -> (Value) in
//			try models.forEach({ (model: Value.Element) in
//				var model = model
////				guard let id: Value.Element.IDValue = try get(keyPath, from: model) else { throw Abort(.badRequest) }
//				let idString = Value.Element.idKeyStringPath
//				guard let json: AnyCodableDictionary = jsonMap[idString] else { throw Abort(.badRequest) }
//				let decoder: JSONDecoder = .default
//				let data = try json.encodeAsJSONData()
//				try decoder.update(&model, from: data)
//
//			})
//			return models
//        }.updateAndReturn(on: database.db, transaction: true)
//	}
//}
//


