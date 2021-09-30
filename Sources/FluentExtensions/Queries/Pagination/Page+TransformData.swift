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

public protocol PageTransformer {
    associatedtype Input
    associatedtype Output
    func transform(datum: Input) throws -> Output
}

public extension Page {
    func transform<Transformer: PageTransformer>(with transformer: Transformer) throws -> Page<Transformer.Output> where Transformer.Input == T {
        try transformDatum(with: transformer.transform)
    }
}

//MARK: SQLRow

public extension Future where Value == Page<SQLRow> {
    func transformDatum<O>(with transformer: @escaping (SQLRow) throws -> O) throws -> Future<Page<O>> {
        return tryMap({try $0.transformDatum(with: transformer)})
    }

    func transformData<O>(with transformer: @escaping ([SQLRow]) throws -> [O]) throws -> Future<Page<O>> {
        return tryMap({try $0.transformData(with: transformer)})
    }

    func transform<Transformer: PageTransformer>(with transformer: Transformer) throws -> Future<Page<Transformer.Output>> where Transformer.Input == SQLRow {
        try transformDatum(with: transformer.transform)
    }
}
