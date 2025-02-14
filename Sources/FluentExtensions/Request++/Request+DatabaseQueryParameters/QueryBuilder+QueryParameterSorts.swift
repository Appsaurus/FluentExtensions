//
//  QueryBuilder+QueryParameterSorts.swift
//  
//
//  Created by Brian Strobach on 9/30/21.
//

public typealias QueryParamFieldKeyConverter = (String) -> String

public extension QueryBuilder {

    func sorted(byQueryParamsAt key: String = "sort",
                convertingKeysWith keyConverter: QueryParamFieldKeyConverter? = nil,
                on req: Request) throws -> Self {
        for sort in try sorts(byQueryParamsAt: key, convertingKeysWith: keyConverter, on: req) {
            _ = self.sort(sort)
        }
        return self
    }

    func sorts(byQueryParamsAt key: String = "sort",
               convertingKeysWith keyConverter: QueryParamFieldKeyConverter? = nil,
               on req: Request) throws -> [DatabaseQuery.Sort] {
        var sorts: [DatabaseQuery.Sort] = []
        if let sort = req.query[String.self, at: key] {
            sorts = try Model.sorts(fromQueryParam: sort, convertingKeysWith: keyConverter)
        }
        return sorts
    }
}

extension Model {
    static func sorts(fromQueryParam queryParamString: String,
                      convertingKeysWith keyConverter: QueryParamFieldKeyConverter? = nil) throws -> [DatabaseQuery.Sort] {
        var sorts: [DatabaseQuery.Sort] = []
        let sortOpts = queryParamString.components(separatedBy: ",")
        for option in sortOpts {
            let split = option.components(separatedBy: ":")

            var field = split[0]
            if let keyConverter = keyConverter {
                field = keyConverter(field)
            }

            let directionParam = split.count == 1 ? "asc" : split[1]
            let querySortDirection = DatabaseQuery.Sort.Direction(directionParam)
            let queryField = DatabaseQuery.Field.path([FieldKey(field)], schema: schema)
            sorts.append(DatabaseQuery.Sort.sort(queryField, querySortDirection))
        }
        return sorts
    }

}
