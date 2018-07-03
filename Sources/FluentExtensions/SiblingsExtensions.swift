//
//  SiblingExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 5/30/18.
//

import Foundation
import Fluent

extension Siblings{
	public static var pivotType: Through.Type {
		return Through.self
	}

	public var pivotType: Through.Type {
		return Through.self
	}
}

/// Left-side
extension Siblings
	where Through: ModifiablePivot, Through.Left == Base, Through.Right == Related, Through.Database: QuerySupporting{
	/// Attaches an array  of models to this relationship.
	@discardableResult
	public func attach(_ models: [Related], on conn: DatabaseConnectable) -> Future<[Through]> {
		return Future.flatMap(on: conn) {
			try models.map({return try Through(self.base, $0)}).save(on: conn)
		}
	}

	/// Pure sugar wrapping isAttached() in order to match child API name
	public func includes(_ model: Through.Right, on conn: DatabaseConnectable) throws -> Future<Bool> {
		return isAttached(model, on: conn)
	}
}

/// Right-side
extension Siblings
	where Through: ModifiablePivot, Through.Left == Related, Through.Right == Base, Through.Database: QuerySupporting{
	/// Attaches an array of models to this relationship.
	@discardableResult
	public func attach(_ models: [Related], on conn: DatabaseConnectable) -> Future<[Through]> {
		return Future.flatMap(on: conn) {
			try models.map({return try Through($0, self.base)}).save(on: conn)
		}
	}
}

