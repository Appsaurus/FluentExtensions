//
//  Model+NextID.swift
//  
//
//  Created by Brian Strobach on 9/2/21.
//

import Fluent

public extension Model where IDValue == Int{
    static func nextID(on database: Database) -> Future<IDValue>{
        let idQuery = query(on: database).sort(\._$id, .descending).first()
        return idQuery.map { value in
            guard let value = value?.id else {
                return 0
            }
            return value + 1
        }
    }
}


public extension QueryBuilder {
    // MARK: Range

    /// Limits the results of this query to the specified maximum.
    ///
    ///     query.limit(5) // returns at most 5 results
    ///
    /// - returns: Query builder for chaining.
    func limit(_ max: Int) -> Self {
        return self.range(0..<max)
    }

    func at(most max: Int) -> Future<[Model]> {
        return limit(max).all()
    }

    func at(most max: Int?) -> Future<[Model]> {
        guard let max = max else { return all() }
        return at(most: max)
    }

}

public extension QueryBuilder {
    func groupBy<T>(_ field: KeyPath<Model, T>?) -> Self {
        guard let field = field else { return self }
        return groupBy(field)
    }

    func groupedValues<T>(of field: KeyPath<Model, T>, limit: Int?) -> Future<[T]> {
        return groupBy(field).values(of: field, limit: limit)
    }

    func values<T>(of field: KeyPath<Model, T>, limit: Int?) -> Future<[T]> {
        return at(most: limit).map{ $0.map { $0[keyPath: field] } }
    }
}

public extension QueryBuilder {

    @discardableResult
    func filter(_ filters: ModelValueFilter<Model>...) -> Self {
        return filter(filters)
    }

    @discardableResult
    func filter(_ filters: [ModelValueFilter<Model>]) -> Self {
        var q = self
        for filter in filters {
            q = q.filter(filter)
        }
        return q
    }
}


public extension Model {

    static func findAll<G>(where filters: ModelValueFilter<Self>...,
                                             groupedBy groupKey: KeyPath<Self, G>? = nil,
                                             limit: Int? = nil, on database: Database) -> Future<[Self]> {
        return findAll(where: filters, groupedBy: groupKey, limit: limit, on: database)
    }

    static func findAll<G>(where filters: [ModelValueFilter<Self>],
                                             groupedBy groupKey: KeyPath<Self, G>? = nil,
                                             limit: Int? = nil,
                                             on database: Database) -> Future<[Self]> {
        return query(on: database).filter(filters).groupBy(groupKey).at(most: limit)
    }

    static func groupedValue<V>(of field: KeyPath<Self, V>,
                                           where filters: [ModelValueFilter<Self>],
                                           limit: Int?,
                                           on database: Database) -> Future<[V]>{

        return query(on: database).filter(filters).groupedValues(of: field, limit: limit)

    }



//    func uniqueValues<T>(of field: KeyPath<Model, T>, limit: Int?) -> Future<[T]> {
//        return groupBy(field).values(of: field, limit: limit)
//    }
}
