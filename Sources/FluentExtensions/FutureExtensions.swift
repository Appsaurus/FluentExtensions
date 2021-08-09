//
//  FutureExtensions.swift
//  Servasaurus
//
//  Created by Brian Strobach on 4/1/18.
//

import Foundation
import Fluent
import Vapor
import CodableExtensions
import RuntimeExtensions

extension IDProperty{
	public func toString() -> String{
        switch self.value{
		case let stringType as String:
			return stringType
		case let intID as Int:
			return "\(intID)"
		case let uuidID as UUID:
			return uuidID.uuidString
		default:
			assertionFailure()
			return ""
		}
	}
}
//
//extension Model{
//	public static var idKeyStringPath: String{
//		return idKey.propertyName
//	}
//}
//
//extension Future where Value: Collection, Value.Element: Model/* & Reflectable*/ {
//
//	public func update(with request: Request) throws -> Future<Value> {
//
//		let decoder: JSONDecoder = .default
//
//		let data =  request.body.data!
//		let jsonArray: [AnyCodableDictionary] = try [AnyCodableDictionary].decode(fromJSON: data, using: decoder)
//        return try update(with: jsonArray, keyedBy: Value.Element.ID, on: request)
//	}
//
//	public func update(with json: [AnyCodableDictionary], keyedBy keyPath: String, on conn: Request) throws -> Future<Value> {
//		let jsonMap: [String : AnyCodableDictionary] = try json.indexed { (dictionary) in
//			guard let id: Any = dictionary[keyPath] else { throw Abort(.badRequest) }
//			return "\(id)"
//		}
//
//		
//		return self.map(to: Value.self) { (models: Value) in
//			try models.forEach({ (model: Value.Element) in
//				var model = model
//				guard let id: Value.Element.ID = try get(keyPath, from: model) else { throw Abort(.badRequest) }
//				let idString = id.toString()
//				guard let json: AnyCodableDictionary = jsonMap[idString] else { throw Abort(.badRequest) }
//				let decoder: JSONDecoder = .default
//				let data = try json.encodeAsJSONData()
//				try decoder.update(&model, from: data)
//
//			})
//			return models
//			}.update(on: conn)
//	}
//}

extension Future {
	public func flattenVoid() -> Future<Void> {
		return map { (_) -> Void in
			return Void()
		}
	}
}
