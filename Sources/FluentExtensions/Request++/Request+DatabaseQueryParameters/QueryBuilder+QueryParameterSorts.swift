//
//  QueryBuilder+QueryParameterSorts.swift
//  
//
//  Created by Brian Strobach on 9/30/21.
//

public extension QueryBuilder {

    func sorted(byQueryParamsAt key: String = "sort", on req: Request) throws -> Self {
        for sort in try sorts(byQueryParamsAt: key, on: req) {
            _ = self.sort(sort)
        }
        return self
    }

    func sorts(byQueryParamsAt key: String = "sort", on req: Request) throws -> [DatabaseQuery.Sort] {
        var sorts: [DatabaseQuery.Sort] = []
        if let sort = req.query[String.self, at: key] {
            sorts = try Model.sorts(fromQueryParam: sort)
        }
        return sorts
    }
}
