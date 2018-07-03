//
//  Model+Reflection.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 7/2/18.
//

import Foundation
import Fluent
import Vapor
import RuntimeExtensions

//extension Future where T: Model & Reflectable  {
//	public func update<M: HTTPMessageContainer>(with container: ContentContainer<M>, on conn: DatabaseConnectable) throws -> Future<T> {
//		return self.map(to: T.self) { (model) in
//			return try model.updateReflectively(with: container)
//			}.update(on: conn)
//	}
//
//}
//extension Model where Self: Reflectable{
//
//	public func setTypedValue<M: HTTPMessageContainer>(for property: ReflectedProperty, from container: ContentContainer<M>) throws{
//		let key = property.path.first!
//		var anyValue: Any?
//		switch property.type{
//		case is Optional<String>.Type:
//			let value: String? = try container.syncGet(at: key)
//			anyValue = value
//		case is Optional<Bool>.Type:
//			let value: Bool? = try container.syncGet(at: key)
//			anyValue = value
//		case is Optional<Double>.Type:
//			let value: Double? = try container.syncGet(at: key)
//			anyValue = value
//		case is Optional<Int>.Type:
//			let value: Int? = try container.syncGet(at: key)
//			anyValue = value
//		case is Optional<Data>.Type:
//			let value: Data? = try container.syncGet(at: key)
//			anyValue = value
//		case is Optional<Date>.Type:
//			let value: Date? = try container.syncGet(at: key)
//			anyValue = value
//			//        case is Optional<ID>.Type:
//			//            let value: ID? = try dataWrapper.syncGet(at: key)
//			anyValue = value
//		case is String.Type:
//			let value: String = try container.syncGet(at: key)
//			anyValue = value
//		case is Bool.Type:
//			let value: Bool = try container.syncGet(at: key)
//			anyValue = value
//		case is Double.Type:
//			let value: Double = try container.syncGet(at: key)
//			anyValue = value
//		case is Int.Type:
//			let value: Int = try container.syncGet(at: key)
//			anyValue = value
//		case is Data.Type:
//			let value: Data = try container.syncGet(at: key)
//			anyValue = value
//		case is Date.Type:
//			let value: Date = try container.syncGet(at: key)
//			anyValue = value
//			//        case is ID.Type:
//			//            let value: ID = try dataWrapper.syncGet(at: key)
//		//            anyValue = value
//		default: break
//		}
//		guard let value = anyValue else { return }
//		try set(value, key: key, for: self)
//	}
//
//	@discardableResult
//	public func updateReflectively<M: HTTPMessageContainer>(with container: ContentContainer<M>) throws -> Self{
//		return try reflectivelyInstantiate(with: container)
//	}
//
//	@discardableResult
//	public func reflectivelyInstantiate<M: HTTPMessageContainer>(with container: ContentContainer<M>) throws -> Self{
//		//		self.id = try json.get(idKey)
//		for property in try type(of: self).reflectProperties(){
//			do{
//				try setTypedValue(for: property, from: container)
//			}
//			catch DecodingError.keyNotFound(_, _){
//				continue
//			}
//		}
//		return self
//	}
//}

extension Model where Self: KVC, Database: QuerySupporting{
	public func updateWithKeyValues(of model: Self, on conn: DatabaseConnectable) throws -> Future<Self> {
		return try updateWithKeyValues(of: model).save(on: conn)
	}
}
