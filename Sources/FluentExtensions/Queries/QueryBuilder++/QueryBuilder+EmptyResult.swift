//
//  QueryBuilder+EmptyResult.swift
//  
//
//  Created by Brian Strobach on 9/1/21.
//

import FluentKit

public extension QueryBuilder{
    func emptyResults() -> [Model] {
        return [Model]()
    }
    func emptyResult() -> Model? {
        return nil
    }
}

