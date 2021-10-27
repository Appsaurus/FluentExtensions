//
//  QueryBuilder+Timestampable.swift
//
//
//  Created by Brian Strobach on 10/26/21.
//

import Fluent

public extension QueryBuilder where Model: Timestampable{

    @discardableResult
    func filterCreated(to range: Range<Date>) -> Self {
        return filter(Model.createdAtKey, to: range)
    }

    @discardableResult
    func filterCreated(to range: ClosedRange<Date>) -> Self {
        return filter(Model.createdAtKey, to: range)
    }

    @discardableResult
    func filterUpdated(to range: Range<Date>) -> Self {
        return filter(Model.updatedAtKey, to: range)
    }

    @discardableResult
    func filterUpdated(to range: ClosedRange<Date>) -> Self {
        return filter(Model.updatedAtKey, to: range)
    }
}
