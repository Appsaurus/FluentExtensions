//
//  Timestampable.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//

import Fluent

public protocol Timestampable: Model {
    associatedtype TimestampFormat: Fluent.TimestampFormat
    var createdAt: Timestamp<TimestampFormat> { get }
    var updatedAt: Timestamp<TimestampFormat> { get }
}

public extension Timestampable {
    static var createdAtKeyPath: TimestampPropertyKeyPath<Self, TimestampFormat> {
        return \.createdAt
    }
}

public protocol SoftDeletable: Model {
    associatedtype TimestampFormat: Fluent.TimestampFormat
    var deletedAt: Timestamp<TimestampFormat> { get }
}

//public protocol Timestampable: Model {
//    associatedtype TimestampFormat: Fluent.TimestampFormat
//    static var createdAtKeyPath: TimestampPropertyKeyPath<Self, TimestampFormat> { get }
//    static var updatedAtKeyPath: TimestampPropertyKeyPath<Self, TimestampFormat> { get }
//}
//
//public protocol SoftDeletable: Model {
//    associatedtype TimestampFormat: Fluent.TimestampFormat
//    static var deletedAtKeyPath: TimestampPropertyKeyPath<Self, TimestampFormat> { get }
//}
