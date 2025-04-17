//
//  Timestampable.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//

import Fluent

public extension Model {
    /// A type alias for timestamp property key paths on a model
    /// - Parameter Format: The timestamp format to use
    typealias TimestampKeyPath<Format> = TimestampPropertyKeyPath<Self, Format> where Format: TimestampFormat
}

/// A protocol that adds timestamp functionality to a model
///
/// Conforming types will track creation and update timestamps automatically
public protocol Timestampable: Model {
    /// The timestamp when the entity was created
    var createdAt: Date? { get set }
    
    /// The timestamp when the entity was last updated
    var updatedAt: Date? { get set }

    /// The format to use for storing timestamps
    associatedtype TimestampFormat: Fluent.TimestampFormat
    
    /// The key path for the creation timestamp
    static var createdAtKey: TimestampKeyPath<TimestampFormat> { get }
    
    /// The key path for the update timestamp
    static var updatedAtKey: TimestampKeyPath<TimestampFormat> { get }
}

/// A protocol that adds soft delete functionality to a model
///
/// Conforming types can be marked as deleted without being removed from the database
public protocol SoftDeletable: Model {
    /// The timestamp when the entity was soft deleted
    var deletedAt: Date? { get set }
}
