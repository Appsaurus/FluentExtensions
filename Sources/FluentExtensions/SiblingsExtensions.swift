//
//  SiblingExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 5/30/18.
//

import Foundation
import FluentKit

public extension SiblingsProperty{
	static var pivotType: Through.Type {
		return Through.self
	}

	var pivotType: Through.Type {
		return Through.self
	}
}

/// Left-side
public extension SiblingsProperty{

    /// Pure sugar wrapping isAttached() in order to match child API name
    func includes(_ model: Through, on database: Database) throws -> Future<Bool> {
        return try self.$pivots.includes(model, on: database)
    }
}

///// Left-side
//public extension SiblingsProperty
//	where Through: ModifiablePivot, Through.Left == Base, Through.Right == Related, Through.Database: QuerySupporting{
//	/// Attaches an array  of models to this relationship.
//	@discardableResult
//	func attach(_ models: [Related], on database: Database) -> Future<[Through]> {
//		return Future.flatMap(on: database) {
//			try models.map({return try Through(self.base, $0)}).save(on: database)
//		}
//	}
//
//	/// Pure sugar wrapping isAttached() in order to match child API name
//	func includes(_ model: Through.Right, on database: Database) throws -> Future<Bool> {
//		return isAttached(model, on: database)
//	}
//}
//
///// Right-side
//public extension Siblings
//	where Through: ModifiablePivot, Through.Left == Related, Through.Right == Base, Through.Database: QuerySupporting{
//	/// Attaches an array of models to this relationship.
//	@discardableResult
//	func attach(_ models: [Related], on database: Database) -> Future<[Through]> {
//		return Future.flatMap(on: database) {
//			try models.map({return try Through($0, self.base)}).save(on: database)
//		}
//	}
//}

