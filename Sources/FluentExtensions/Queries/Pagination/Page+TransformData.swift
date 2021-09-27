//
//  File.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//

import SQLKit

//extension LegacyPaginated {
//    func transformDatum<R>(to type: R.Type = R.self, _ transform: @escaping (M) throws -> R) throws -> LegacyPaginated<R> {
//        return LegacyPaginated<R>(page: self.page, data: try data.map(transform))
//    }
//    func transformData<R>(to type: R.Type = R.self, _ transform: @escaping ([M]) throws -> [R]) throws -> LegacyPaginated<R> {
//        return LegacyPaginated<R>(page: self.page, data: try transform(data))
//    }
//}

public extension Page {
    func transformDatum<O>(with transformer: (T) throws -> O) throws -> Page<O> {
        return Page<O>(items: try items.map(transformer), metadata: metadata)
    }

    func transformData<O>(with transformer: ([T]) throws -> [O]) throws -> Page<O> {
        return Page<O>(items: try transformer(items), metadata: metadata)
    }
}


extension Future where Value == Page<SQLRow> {

}


