//
//  Timestampable.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//

import Fluent

public protocol Timestampable: Model {
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
}

public protocol SoftDeletable: Model {
    var deletedAt: Date? { get set }
}
