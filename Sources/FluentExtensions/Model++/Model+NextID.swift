//
//  Model+NextID.swift
//  
//
//  Created by Brian Strobach on 9/2/21.
//

import Fluent

extension Model where IDValue == Int{
    public static func nextID(on database: Database) -> Future<IDValue>{
        let idQuery = query(on: database).sort(\._$id, .descending).first()
        return idQuery.map { value in
            guard let value = value?.id else {
                return 0
            }
            return value + 1
        }
    }
}


extension QueryBuilder {
    // MARK: Range

    /// Limits the results of this query to the specified maximum.
    ///
    ///     query.limit(5) // returns at most 5 results
    ///
    /// - returns: Query builder for chaining.
    public func limit(_ max: Int) -> Self {
        return self.range(0..<max)
    }

    public func at(most max: Int) -> Future<[Model]> {
        return limit(max).all()
    }

    public func at(most max: Int?) -> Future<[Model]> {
        guard let max = max else { return all() }
        return at(most: max)
    }

}

extension QueryBuilder {
    public func groupBy<T>(_ field: KeyPath<Model, T>?) -> Self {
        guard let field = field else { return self }
        return groupBy(field)
    }

    public func groupedValues<T>(of field: KeyPath<Model, T>, limit: Int?) -> Future<[T]> {
        return groupBy(field).values(of: field, limit: limit)
    }

    public func values<T>(of field: KeyPath<Model, T>, limit: Int?) -> Future<[T]> {
        return at(most: limit).map{ $0.map { $0[keyPath: field] } }
    }
}

extension QueryBuilder {

    @discardableResult
    public func filter(_ filters: ModelValueFilter<Model>...) -> Self {
        return filter(filters)
    }

    @discardableResult
    public func filter(_ filters: [ModelValueFilter<Model>]) -> Self {
        var q = self
        for filter in filters {
            q = q.filter(filter)
        }
        return q
    }
}


extension Model {

    public static func findAll<G>(where filters: ModelValueFilter<Self>...,
                                             groupedBy groupKey: KeyPath<Self, G>? = nil,
                                             limit: Int? = nil, on database: Database) -> Future<[Self]> {
        return findAll(where: filters, groupedBy: groupKey, limit: limit, on: database)
    }

    public static func findAll<G>(where filters: [ModelValueFilter<Self>],
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



//    public func uniqueValues<T>(of field: KeyPath<Model, T>, limit: Int?) -> Future<[T]> {
//        return groupBy(field).values(of: field, limit: limit)
//    }
}
