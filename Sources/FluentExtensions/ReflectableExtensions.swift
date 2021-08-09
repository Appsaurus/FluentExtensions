//
//  ReflectableExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 6/27/18.
//

import Foundation
import Vapor
import Fluent

//extension Reflectable{
//	public static func propertyNamed(_ name: String) throws -> ReflectedProperty? {
//		return try reflectProperties().named(name)
//	}
//
//	public static func hasProperty(named name: String) throws -> Bool{
//		return try propertyNamed(name) != nil
//	}
//
//	public static func fluentProperty(named name: String) throws -> FluentProperty?{
//		guard let property = try propertyNamed(name) else { return nil }
//		return FluentProperty.reflected(property, rootType: self)
//	}
//}
//
//extension ReflectedProperty{
//	public var name: String{
//		return path.last!
//	}
//	public var fullPath: String{
//		return path.joined(separator: ".")
//	}
//}
//
//extension Array where Element == ReflectedProperty{
//	public func named(_ name: String) -> ReflectedProperty? {
//		return first(where: {$0.name == name})
//	}
//}
