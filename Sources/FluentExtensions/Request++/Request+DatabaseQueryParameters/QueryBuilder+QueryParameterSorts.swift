/// A type that converts field keys from query parameters to database field keys
public typealias QueryParamFieldKeyConverter = (String) -> String

public extension QueryBuilder {
    /// Applies sorting to the query builder based on query parameters from the request
    ///
    /// This method parses sort parameters from the request's query string and applies them to the query builder.
    /// The sort format in the query string should be: `?sort=field:direction,field2:direction2`
    /// where direction is either 'asc' or 'desc'. If direction is omitted, 'asc' is assumed.
    ///
    /// - Parameters:
    ///   - key: The query parameter key to look for sort instructions (defaults to "sort")
    ///   - keyConverter: Optional closure to convert field names from the query parameter to database field names
    ///   - req: The incoming request containing query parameters
    /// - Returns: Self (QueryBuilder) for method chaining
    /// - Throws: Any errors that occur during parameter processing
    func sorted(byQueryParamsAt key: String = "sort",
                convertingKeysWith keyConverter: QueryParamFieldKeyConverter? = nil,
                on req: Request) throws -> Self {
        for sort in try sorts(byQueryParamsAt: key, convertingKeysWith: keyConverter, on: req) {
            _ = self.sort(sort)
        }
        return self
    }
    
    /// Generates an array of database sorts based on query parameters from the request
    ///
    /// - Parameters:
    ///   - key: The query parameter key to look for sort instructions (defaults to "sort")
    ///   - keyConverter: Optional closure to convert field names from the query parameter to database field names
    ///   - req: The incoming request containing query parameters
    /// - Returns: Array of DatabaseQuery.Sort instructions
    /// - Throws: Any errors that occur during parameter processing
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
    /// Creates an array of database sorts from a query parameter string
    /// 
    /// This method parses a comma-separated string of sort instructions where each instruction
    /// is in the format "field:direction". For example: "name:asc,age:desc"
    ///
    /// - Parameters:
    ///   - queryParamString: The string containing sort instructions
    ///   - keyConverter: Optional closure to convert field names from the query parameter to database field names
    /// - Returns: Array of DatabaseQuery.Sort instructions
    /// - Throws: Any errors that occur during parameter processing
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
            
            // Default to ascending if no direction specified
            let directionParam = split.count == 1 ? "asc" : split[1]
            let querySortDirection = DatabaseQuery.Sort.Direction(directionParam)
            let queryField = DatabaseQuery.Field.path([FieldKey(field)], schema: schema)
            sorts.append(DatabaseQuery.Sort.sort(queryField, querySortDirection))
        }
        return sorts
    }
}
