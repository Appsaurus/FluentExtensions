//
//  URLQueryContainer+DecodePageRequest.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//

public extension URLQueryContainer {
    func decodePageRequest(pageKey: String = Pagination.Defaults.pageKey,
                           perPageKey: String = Pagination.Defaults.perPageKey,
                           defaultPageSize: Int = Pagination.Defaults.pageSize,
                           defaultMaxPageSize: Int? = Pagination.Defaults.maxPageSize) throws -> PageRequest {
        let page = try get(Int?.self, at: pageKey) ?? 1
        var per = try get(Int?.self, at: perPageKey) ?? defaultPageSize
        if let maxPer = defaultMaxPageSize, per > maxPer {
            per = maxPer
        }
        return PageRequest(page: page, per: per)
    }
}

