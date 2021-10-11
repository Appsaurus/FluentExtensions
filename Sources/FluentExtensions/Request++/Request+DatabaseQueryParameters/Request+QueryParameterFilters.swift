//
//  Request+QueryParameterFilters.swift
//  
//
//  Created by Brian Strobach on 9/7/21.
//

import Vapor
import Foundation
import Fluent
import RuntimeExtensions
import CodableExtensions
import Codability

public class QueryParameterFilterParser {
    
}
public extension URLQueryContainer {
    
    func parseFilter<V: QueryableProperty, M: Model>(for keyPath: KeyPath<M,V>,
                                                     withQueryValueAt queryParameterKey: String? = nil,
                                                     as queryValueType: Any.Type? = nil) throws -> QueryParameterFilter? {
        try parseFilter(for: M.self,
                        at: keyPath.codingKeys,
                        withQueryValueAt: queryParameterKey,
                        as: queryValueType ?? V.self.Value)
    }

    func parseFilter(for schema: Schema.Type,
                     at keyPath: CodingKeyRepresentable...,
                     withQueryValueAt queryParameterKey: String? = nil,
                     as queryValueType: Any.Type? = nil) throws -> QueryParameterFilter? {
        try parseFilter(for: schema, at: keyPath, withQueryValueAt: queryParameterKey, as: queryValueType)

    }
    func parseFilter(for schema: Schema.Type,
                     at keyPath: [CodingKeyRepresentable],
                     withQueryValueAt queryParameterKey: String? = nil,
                     as queryValueType: Any.Type? = nil) throws -> QueryParameterFilter? {
        let fieldName = keyPath.map({$0.codingKey.stringValue}).joined(separator: ".")
        return try QueryParameterFilter(schema: schema,
                                              fieldName: fieldName,
                                              withQueryValueAt: queryParameterKey ?? fieldName,
                                              as: queryValueType,
                                              from: self)
    }
}


extension Model {
    static func sorts(fromQueryParam queryParamString: String) throws -> [DatabaseQuery.Sort] {
        var sorts: [DatabaseQuery.Sort] = []
        let sortOpts = queryParamString.components(separatedBy: ",")
        for option in sortOpts {
            let split = option.components(separatedBy: ":")

            let field = split[0]
//            let fieldKeys = field.components(separatedBy: ".").compactMap({FieldKey($0)})
            let directionParam = split.count == 1 ? "asc" : split[1]
            let querySortDirection = DatabaseQuery.Sort.Direction(directionParam)
            let queryField = DatabaseQuery.Field.path(FieldKey(field), schema: schema)
            sorts.append(DatabaseQuery.Sort.sort(queryField, querySortDirection))
        }
        return sorts
    }

}

internal struct FilterConfig {
    public var method: QueryParameterFilter.Method
    public var value: String
}

internal let FILTER_CONFIG_REGEX = "(\(QueryParameterFilter.Method.allCases.map { $0.rawValue }.joined(separator: "|")))?:?(.*)"

internal extension String {
    var toFilterConfig: FilterConfig {
        let result = capturedGroups(withRegex: FILTER_CONFIG_REGEX)

        var method = QueryParameterFilter.Method.equal

        if let rawValue = result[0], let qfm = QueryParameterFilter.Method(rawValue: rawValue) {
            method = qfm
        }

        return FilterConfig(method: method, value: result[1] ?? "")
    }

    func capturedGroups(withRegex pattern: String) -> [String?] {
        var results = [String?]()

        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            return results
        }

        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: count))

        guard let match = matches.first else { return results }

        let lastRangeIndex = match.numberOfRanges - 1
        guard lastRangeIndex >= 1 else { return results }

        for i in 1 ... lastRangeIndex {
            let capturedGroupIndex = match.range(at: i)

            let matchedString: String? = capturedGroupIndex.location == NSNotFound ? nil : NSString(string: self).substring(with: capturedGroupIndex)

            results.append(matchedString)
        }

        return results
    }
}


