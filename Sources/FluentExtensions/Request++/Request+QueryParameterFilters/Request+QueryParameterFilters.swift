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


public extension Request {
    @discardableResult
    func stringKeyPathFilter<V: QueryableProperty, M: Model>(for keyPath: KeyPath<M,V>,
                                                             withQueryValueAt queryParameterKey: String? = nil,
                                                             as queryValueType: Any.Type? = nil) throws -> StringKeyPathFilter? {
        try stringKeyPathFilter(for: keyPath.codingKeys, withQueryValueAt: queryParameterKey, as: queryValueType)
    }

    func stringKeyPathFilter(for keyPath: CodingKeyRepresentable...,
                             withQueryValueAt queryParameterKey: String? = nil,
                             as queryValueType: Any.Type? = nil) throws -> StringKeyPathFilter? {
        try stringKeyPathFilter(for: keyPath, withQueryValueAt: queryParameterKey, as: queryValueType)

    }
    func stringKeyPathFilter(for keyPath: [CodingKeyRepresentable],
                             withQueryValueAt queryParameterKey: String? = nil,
                             as queryValueType: Any.Type? = nil) throws -> StringKeyPathFilter? {
        let name = queryParameterKey ?? keyPath.map({$0.codingKey.stringValue}).joined(separator: ".")
        guard let filter = try queryParameterFilter(name: name, as: queryValueType) else {
            return nil
        }
        return StringKeyPathFilter(keyPath: keyPath, filter: filter)
    }

    func queryParameterFilter(name: String, as queryValueType: Any.Type? = nil) throws -> QueryParameterFilter? {

        let decoder = URLEncodedFormDecoder()

        guard let config = query[String.self, at: name] else {
            return nil
        }

        let filterConfig = config.toFilterConfig

        let method = filterConfig.method
        let value = filterConfig.value

        let multiple = [.in, .notIn].contains(method)
        var filterValue: QueryParameterFilter.Value<String, [String]>

        if multiple {
            let str = value.components(separatedBy: ",").map { "\(name)[]=\($0)" }.joined(separator: "&")
            filterValue = try .multiple(decoder.decode(SingleValueDecoder.self, from: str).get(at: [name.codingKey]))
        } else {
            let str = "\(name)=\(value)"
            filterValue = try .single(decoder.decode(SingleValueDecoder.self, from: str).get(at: [name.codingKey]))
        }
        return QueryParameterFilter(name: name, method: method, value: filterValue, queryValueType: queryValueType)
    }
}


extension Model {
    static func sorts(fromQueryParam queryParamString: String) throws -> [DatabaseQuery.Sort] {
        var sorts: [DatabaseQuery.Sort] = []
        let sortOpts = queryParamString.components(separatedBy: ",")
        for option in sortOpts {
            let split = option.components(separatedBy: ":")

            let field = split[0]

            let directionParam = split.count == 1 ? "asc" : split[1]
            let querySortDirection = DatabaseQuery.Sort.Direction(directionParam)
            let queryField = DatabaseQuery.Field.path([FieldKey(field)], schema: schema)
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


