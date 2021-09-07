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


//public extension Request {
//    func filterRange<M, C>(for keyPath: KeyPath<M, C>,
//                           at queryKeyPath: Core.BasicKeyRepresentable...) -> ClosedRange<C>? where C: Strideable & Codable {
//        return self.query[ClosedRange<C>.self, at: queryKeyPath]
//    }
//}
public struct QueryParameterSearchFilter {
    var name: String
    var value: String
}

//extension Request {
//    func queryParameterSearchFilter(name: String) throws -> QueryParameterSearchFilter? {
//        let decoder = try make(ContentCoders.self).requireDataDecoder(for: .urlEncodedForm)
//
//        guard let config = query[String.self, at: name] else {
//            return nil
//        }
//    }
//}


public extension Request {

    func stringKeyPathFilter(for keyPath: CodingKeyRepresentable...,
                             at queryParameterName: String? = nil) throws -> StringKeyPathFilter? {
        let name = queryParameterName ?? "\(String(describing: keyPath.last))"
        guard let filter = try queryParameterFilter(name: name) else {
            return nil
        }
        return StringKeyPathFilter(keyPath: keyPath, filter: filter)
    }

    func queryParameterFilter(name: String) throws -> QueryParameterFilter? {


        let decoder = URLEncodedFormDecoder()

        guard let config = query[String.self, at: name] else {
            return nil
        }

        let filterConfig = config.toFilterConfig

        let method = filterConfig.method
        let value = filterConfig.value

        let multiple = [.in, .notIn].contains(method)
        var filterValue: FilterValue<String, [String]>

        if multiple {
            let str = value.components(separatedBy: ",").map { "\(name)[]=\($0)" }.joined(separator: "&")
            filterValue = try .multiple(decoder.decode(SingleValueDecoder.self, from: str).get(at: [name.codingKey]))
        } else {
            let str = "\(name)=\(value)"
            filterValue = try .single(decoder.decode(SingleValueDecoder.self, from: str).get(at: [name.codingKey]))
        }
        return QueryParameterFilter(name: name, method: method, value: filterValue)
    }
}


extension Model {
    static func sorts(fromQueryParam queryParamString: String) throws -> [DatabaseQuery.Sort] {
        var sorts: [DatabaseQuery.Sort] = []
        let sortOpts = queryParamString.components(separatedBy: ",")
        for option in sortOpts {
            let split = option.components(separatedBy: ":")

            let field = split[0]

            let direction = split.count == 1 ? "asc" : split[1]

            let querySortDirection = DatabaseQuery.Sort.Direction.custom(direction)
//            guard let querySortDirection = DatabaseQuery.Sort.Direction.string(direction) else {
//                continue
//            }

            let queryField = DatabaseQuery.Field.path([field.fieldKey], schema: schema)
            sorts.append(DatabaseQuery.Sort.sort(queryField, querySortDirection))
        }
        return sorts
    }

}

//public extension DatabaseQuery.Sort.Direction {
//    init?(_ string: String) {
//        guard ["asc", "desc"].contains(string) else {
//            return
//        }
//        self = (string == "asc" ? .ascending : .descending)
//    }
//}
fileprivate extension String {
    var fieldKey: FieldKey{
        FieldKey(self)
    }
}

public struct StringKeyPathFilter {
    var keyPath: [CodingKeyRepresentable]
    var filter: QueryParameterFilter
}

public struct QueryParameterFilter {
    var name: String
    var method: QueryFilterMethod
    var value: FilterValue<String, [String]>

    func queryField(for schema: String) -> DatabaseQuery.Field {
        return .path([name.fieldKey], schema: schema)
    }

//
//    func databaseQueryFilter(for schema: String) -> DatabaseQuery.Filter {
//        DatabaseQuery.Filter.value(.path([name.fieldKey], schema: schema), <#T##DatabaseQuery.Filter.Method#>, <#T##DatabaseQuery.Value#>)
//    }
}


struct FilterConfig {
    var method: QueryFilterMethod
    var value: String
}

internal let FILTER_CONFIG_REGEX = "(\(QueryFilterMethod.allCases.map { $0.rawValue }.joined(separator: "|")))?:?(.*)"

internal extension String {
    var toFilterConfig: FilterConfig {
        let result = capturedGroups(withRegex: FILTER_CONFIG_REGEX)

        var method = QueryFilterMethod.equal

        if let rawValue = result[0], let qfm = QueryFilterMethod(rawValue: rawValue) {
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


internal enum FilterValue<S, M> {
    case single(S)
    case multiple(M)

}

extension FilterValue where S == String, M == [String] {
    func to(type: Any.Type) -> AnyCodable {

        switch self {
            case .single(let value):
                var codableValue: AnyCodable? = nil
                if type == Bool.self {
                    codableValue = Bool(value)?.wrapAsAnyCodable()
                }
                else if type ==  Int.self || type == Int?.self {
                    codableValue = Int(value)?.wrapAsAnyCodable()
                }

                else if type == Double.self {
                    codableValue = Double(value)?.wrapAsAnyCodable()
                }

                else if type ==  Float.self {
                    codableValue = Float(value)?.wrapAsAnyCodable()
                }
                return codableValue ?? value.wrapAsAnyCodable()
            case .multiple(let values):
                return values.map({FilterValue.single($0).to(type: type)}).wrapAsAnyCodable()
        }

    }

    //    func toValues<T>(type: [T].Type) -> [T]? {
    //        if case let .multiple(values) = self {
    //            return values.map({FilterValue.single($0).to(type: T.self)})
    //        }
    //    }
}

internal enum QueryFilterMethod: String {
    case equal = "eq"
    case notEqual = "neq"
    case `in` = "in"
    case notIn = "nin"
    case greaterThan = "gt"
    case greaterThanOrEqual = "gte"
    case lessThan = "lt"
    case lessThanOrEqual = "lte"
    case startsWith = "sw"
    case notStartsWith = "nsw"
    case endsWith = "ew"
    case notEndsWith = "new"
    case contains = "ct"
    case notContains = "nct"
}

#if swift(>=4.2)
extension QueryFilterMethod: CaseIterable {}
#else
extension QueryFilterMethod {
    static var allCases: [QueryFilterMethod] {
        return [
            .equal,
            .notEqual,
            .in,
            .notIn,
            .greaterThan,
            .greaterThanOrEqual,
            .lessThan,
            .lessThanOrEqual,
            .startsWith,
            .notStartsWith,
            .endsWith,
            .notEndsWith,
            .contains,
            .notContains,
        ]
    }
}
#endif

