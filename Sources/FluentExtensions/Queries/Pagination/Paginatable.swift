//
//  Paginatable.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//


public struct Pagination {
    public class Defaults {
        public static var pageSize: Int = 10
        public static var maxPageSize: Int? = nil
        public static var pageKey = "page"
        public static var perPageKey = "per"
    }
}

public protocol Paginatable {
    static var defaultPageSize: Int { get }
    static var maxPageSize: Int? { get }
//    static var defaultPageSorts: [DatabaseQuery.Sort] { get }

}

// MARK: - Defaults

public extension Paginatable {

    static var defaultPageSize: Int {
        return Pagination.Defaults.pageSize
    }

    static var maxPageSize: Int? {
        return Pagination.Defaults.maxPageSize
    }
}

extension Paginatable where Self: Model {
    static var defaultPageSorts: [DatabaseQuery.Sort] {
        return [
            .sort(idPropertyKeyPath, .descending)
        ]
    }
}

extension Paginatable where Self: Timestampable {
    public static var defaultPageSorts: [DatabaseQuery.Sort] {
        return [
            .sort(createdAtKeyPath, .descending)
        ]
    }
}

