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

extension ID{
	public func toString() -> String{
		switch self{
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

extension Model{
	public static var idKeyStringPath: String{
		return idKey.propertyName
	}
}

extension Future where T: Collection, T.Element: Model & Reflectable {

	public func update(with request: Request) throws -> Future<[T.Element]> {

		let decoder: JSONDecoder = .default
		let data =  request.http.body.data!
		let jsonArray: [AnyCodableDictionary] = try [AnyCodableDictionary].decode(fromJSON: data, using: decoder)
		return try update(with: jsonArray, keyedBy: T.Element.idKeyStringPath, on: request)
	}

	public func update(with json: [AnyCodableDictionary], keyedBy keyPath: String, on conn: Request) throws -> Future<[T.Element]> {
		let jsonMap: [String : AnyCodableDictionary] = try json.indexed { (dictionary) in
			guard let id: Any = dictionary[keyPath] else { throw Abort(.badRequest) }
			return "\(id)"
		}

		
		return self.map(to: T.self) { (models: T) in
			try models.forEach({ (model: T.Element) in
				var model = model
				guard let id: T.Element.ID = try get(keyPath, from: model) else { throw Abort(.badRequest) }
				let idString = id.toString()
				guard let json: AnyCodableDictionary = jsonMap[idString] else { throw Abort(.badRequest) }
				let decoder: JSONDecoder = .default
				let data = try json.encodeAsJSONData()
				try decoder.update(&model, from: data)

			})
			return models
			}.update(on: conn)
	}
}

extension Future {
	public func flattenVoid() -> Future<Void> {
		return map(to: Void.self) { (_) -> Void in
			return Void()
		}
	}
}
