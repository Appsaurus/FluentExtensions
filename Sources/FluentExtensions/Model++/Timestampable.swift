//
//  Timestampable.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//

import Fluent

public protocol Timestampable: Model {
    associatedtype TimestampFormat: Fluent.TimestampFormat
    var createdAt: Timestamp<TimestampFormat> { get set }
    var updatedAt: Timestamp<TimestampFormat> { get set }
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
