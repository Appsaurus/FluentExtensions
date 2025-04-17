//
//  URLQueryContainer+DecodePageRequest.swift
//  
//
//  Created by Brian Strobach on 9/25/21.
//

/// Extension providing pagination request decoding capabilities to URLQueryContainer
public extension URLQueryContainer {
    /// Decodes pagination parameters from URL query parameters
    /// - Parameters:
    ///   - pageKey: The query parameter key for the page number
    ///   - perPageKey: The query parameter key for items per page
    ///   - defaultPageSize: The default number of items per page if not specified
    ///   - defaultMaxPageSize: The maximum allowed items per page
    /// - Returns: A configured PageRequest instance
    /// - Throws: Any errors that occur during parameter decoding
    func decodePageRequest(
        pageKey: String = Pagination.Defaults.pageKey,
        perPageKey: String = Pagination.Defaults.perPageKey,
        defaultPageSize: Int = Pagination.Defaults.pageSize,
        defaultMaxPageSize: Int? = Pagination.Defaults.maxPageSize
    ) throws -> PageRequest {
        let page = try get(Int?.self, at: pageKey) ?? 1
        var per = try get(Int?.self, at: perPageKey) ?? defaultPageSize
        if let maxPer = defaultMaxPageSize, per > maxPer {
            per = maxPer
        }
        return PageRequest(page: page, per: per)
    }
}
