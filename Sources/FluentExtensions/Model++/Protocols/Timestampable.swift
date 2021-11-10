//
//  Timestampable.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//

import Fluent


public extension Model {
    typealias TimestampKeyPath<Format> = TimestampPropertyKeyPath<Self, Format> where Format: TimestampFormat
}

public protocol Timestampable: Model {
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }

    associatedtype TimestampFormat: Fluent.TimestampFormat
    static var createdAtKey: TimestampKeyPath<TimestampFormat> { get }
    static var updatedAtKey: TimestampKeyPath<TimestampFormat> { get }
}

public protocol SoftDeletable: Model {
    var deletedAt: Date? { get set }
}
