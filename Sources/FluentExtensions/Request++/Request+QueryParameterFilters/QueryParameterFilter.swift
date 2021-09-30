//
//  QueryParameterFilter.swift
//  
//
//  Created by Brian Strobach on 9/29/21.
//

import VaporExtensions
import Codability

public class QueryParameterFilter {

    public var name: String
    public var method: QueryParameterFilter.Method
    public var value: Value<String, [String]>
    public var queryValueType: Any.Type? = nil

    public enum Value<S, M> {
        case single(S)
        case multiple(M)
    }

    public enum Method: String {
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

    public func queryField(for schema: String) -> DatabaseQuery.Field {
        return .path([FieldKey(name)], schema: schema)
    }
    internal init(name: String, method: QueryParameterFilter.Method, value: QueryParameterFilter.Value<String, [String]>, queryValueType: Any.Type? = nil) {
        self.name = name
        self.method = method
        self.value = value
        self.queryValueType = queryValueType
    }
//
//    func databaseQueryFilter(for schema: String) -> DatabaseQuery.Filter {
//        DatabaseQuery.Filter.value(.path([name.fieldKey], schema: schema), <#T##DatabaseQuery.Filter.Method#>, <#T##DatabaseQuery.Value#>)
//    }

}

#if swift(>=4.2)
extension QueryParameterFilter.Method: CaseIterable {}
#else
public extension QueryParameterFilter.Method {
    static var allCases: [QueryParameterFilter.Method] {
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

extension QueryParameterFilter.Value where S == String, M == [String] {
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
                return values.map({QueryParameterFilter.Value.single($0).to(type: type)}).wrapAsAnyCodable()
        }

    }

    //    func toValues<T>(type: [T].Type) -> [T]? {
    //        if case let .multiple(values) = self {
    //            return values.map({FilterValue.single($0).to(type: T.self)})
    //        }
    //    }
}
