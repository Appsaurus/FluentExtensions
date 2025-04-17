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

/// Extension providing transformation capabilities for paginated results
public extension Page {
    /// Transforms individual items in the page using a provided transformation closure.
    /// - Parameter transformer: A closure that transforms each item from type T to type O.
    /// - Returns: A new `Page` containing the transformed items of type O.
    /// - Throws: Any errors encountered during the transformation process.
    func transformDatum<O>(with transformer: (T) throws -> O) throws -> Page<O> {
        return Page<O>(items: try items.map(transformer), metadata: metadata)
    }

    /// Transforms the entire collection of items using a provided transformation closure.
    /// - Parameter transformer: A closure that transforms the collection of items from [T] to [O].
    /// - Returns: A new `Page` containing the transformed items of type O.
    /// - Throws: Any errors encountered during the transformation process.
    func transformData<O>(with transformer: ([T]) throws -> [O]) throws -> Page<O> {
        return Page<O>(items: try transformer(items), metadata: metadata)
    }
}

/// Protocol defining an object capable of transforming paginated data.
public protocol PageTransformer {
    /// The input type that will be transformed
    associatedtype Input
    /// The output type after transformation
    associatedtype Output
    
    /// Transforms a single input item to output
    /// - Parameter datum: The input item to transform
    /// - Returns: The transformed output
    /// - Throws: Any errors encountered during transformation
    func transform(datum: Input) throws -> Output
}

public extension Page {
    /// Transforms the page using a PageTransformer implementation
    /// - Parameter transformer: The transformer to use for converting items
    /// - Returns: A new `Page` containing the transformed items
    /// - Throws: Any errors encountered during transformation
    func transform<Transformer: PageTransformer>(with transformer: Transformer) throws -> Page<Transformer.Output> where Transformer.Input == T {
        try transformDatum(with: transformer.transform)
    }
}
