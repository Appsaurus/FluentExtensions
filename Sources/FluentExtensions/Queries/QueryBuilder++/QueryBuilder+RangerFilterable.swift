//
//  QueryBuilder+RangerFilterable.swift
//
//
//  Created by Brian Strobach on 9/1/21.
//
import FluentKit
import Fluent
import SQLKit

/// A type that can be used in range-based filtering operations.
/// The type must conform to both `Strideable` and `Codable` protocols.
public typealias RangeFilterable = Strideable & Codable

public extension QueryBuilder {
    /// Filters query results based on a range of values for a given property.
    /// - Parameters:
    ///   - keyPath: The key path to the property being filtered
    ///   - range: The range of values to filter by
    /// - Returns: The modified query builder
    @discardableResult
    func filter<P: QueryableProperty>(_ keyPath: KeyPath<Model, P>, to range: Range<P.Value>) -> Self where P.Value: Strideable {
        return group(.and) {
            $0.filter(keyPath >= range.lowerBound)
            $0.filter(keyPath <= range.upperBound)
        }
    }

    /// Filters query results based on a range of optional values for a given property.
    /// - Parameters:
    ///   - keyPath: The key path to the property being filtered
    ///   - range: The range of values to filter by
    /// - Returns: The modified query builder
    @discardableResult
    func filter<P: QueryableProperty>(_ keyPath: KeyPath<Model, P>, to range: Range<P.Value>) -> Self
    where P.Value: Vapor.OptionalType & Strideable, P.Value.WrappedType: RangeFilterable {
        return group(.and) {
            $0.filter(keyPath >= range.lowerBound)
            $0.filter(keyPath <= range.upperBound)
        }
    }

    /// Filters query results based on a closed range of values for a given property.
    /// - Parameters:
    ///   - keyPath: The key path to the property being filtered
    ///   - range: The closed range of values to filter by
    /// - Returns: The modified query builder
    @discardableResult
    func filter<P: QueryableProperty>(_ keyPath:  KeyPath<Model, P>, to range: ClosedRange<P.Value>) -> Self where P.Value: Strideable {
        return group(.and) {
            $0.filter(keyPath >= range.lowerBound)
            $0.filter(keyPath <= range.upperBound)
        }
    }

    /// Filters query results based on a closed range of optional values for a given property.
    /// - Parameters:
    ///   - keyPath: The key path to the property being filtered
    ///   - range: The closed range of values to filter by
    /// - Returns: The modified query builder
    @discardableResult
    func filter<P: QueryableProperty>(_ keyPath:  KeyPath<Model, P>, to range: ClosedRange<P.Value>) -> Self
    where P.Value: Vapor.OptionalType & Strideable, P.Value.WrappedType: RangeFilterable {
        return group(.and) {
            $0.filter(keyPath >= range.lowerBound)
            $0.filter(keyPath <= range.upperBound)
        }
    }

    /// Filters query results based on a range specified in a URL query parameter.
    /// - Parameters:
    ///   - keyPath: The key path to the property being filtered
    ///   - parameter: The URL query parameter containing the range
    ///   - request: The request containing the query parameters
    /// - Returns: The modified query builder
    @discardableResult
    func filter<P: QueryableProperty>(_ keyPath: KeyPath<Model, P>, toRangeAt parameter: String, on request: Request) -> Self where P.Value: Strideable {
        if let param = request.query[String.self, at: parameter],
           let range = try? ClosedRange<P.Value>(string: param) {
            filter(keyPath, to: range)
        }
        return self
    }

    /// Filters query results based on a range of optional values specified in a URL query parameter.
    /// - Parameters:
    ///   - keyPath: The key path to the property being filtered
    ///   - parameter: The URL query parameter containing the range
    ///   - request: The request containing the query parameters
    /// - Returns: The modified query builder
    @discardableResult
    func filter<P: QueryableProperty>(_ keyPath: KeyPath<Model, P>, toRangeAt parameter: String, on request: Request) -> Self
    where P.Value: Vapor.OptionalType & Strideable, P.Value.WrappedType: RangeFilterable {
        if let param = request.query[String.self, at: parameter],
           let range = try? ClosedRange<P.Value>(string: param) {
            filter(keyPath, to: range)
        }
        return self
    }

    //MARK: - Timestamp Filtering

    /// Filters query results based on a closed range of dates for a timestamp property.
    /// - Parameters:
    ///   - keyPath: The key path to the timestamp property
    ///   - range: The closed range of dates to filter by
    /// - Returns: The modified query builder
    @discardableResult
    func filter<F: TimestampFormat, P: TimestampProperty<Model, F>>(_ keyPath: KeyPath<Model, P>, to range: ClosedRange<Date>) -> Self {
        return group(.and) {
            $0.filter(keyPath >= range.lowerBound)
            $0.filter(keyPath <= range.upperBound)
        }
    }

    /// Filters query results based on a range of dates for a timestamp property.
    /// - Parameters:
    ///   - keyPath: The key path to the timestamp property
    ///   - range: The range of dates to filter by
    /// - Returns: The modified query builder
    func filter<F: TimestampFormat, P: TimestampProperty<Model, F>>(_ keyPath: KeyPath<Model, P>, to range: Range<Date>) -> Self {
        return group(.and) {
            $0.filter(keyPath >= range.lowerBound)
            $0.filter(keyPath <= range.upperBound)
        }
    }

    /// Filters query results based on a range of dates specified in a URL query parameter.
    /// - Parameters:
    ///   - keyPath: The key path to the timestamp property
    ///   - parameter: The URL query parameter containing the range
    ///   - request: The request containing the query parameters
    /// - Returns: The modified query builder
    @discardableResult
    func filter<F: TimestampFormat, P: TimestampProperty<Model, F>>(_ keyPath: KeyPath<Model, P>, toRangeAt parameter: String, on request: Request) -> Self {
        if let param = request.query[String.self, at: parameter],
           let range = try? ClosedRange<Date>(string: param) {
            filter(keyPath, to: range)
        }
        return self
    }
}

/// Extension to handle range query parameters in URL queries
public extension URLQueryContainer {
    /// Attempts to extract and parse a range from a query parameter.
    /// - Parameter parameter: The query parameter key
    /// - Returns: A closed range if successfully parsed, nil otherwise
    func range<V: RangeFilterable>(at parameter: String) -> ClosedRange<V>? {
        return try? rangeThrowing(at: parameter)
    }

    /// Attempts to extract and parse a range from a query parameter, throwing an error if parsing fails.
    /// - Parameter parameter: The query parameter key
    /// - Returns: A closed range if successfully parsed, nil if parameter doesn't exist
    /// - Throws: An error if the range string is malformed
    func rangeThrowing<V: RangeFilterable>(at parameter: String) throws -> ClosedRange<V>? {
        guard let param = self[String.self, at: parameter] else {
            return nil
        }
        return try ClosedRange<V>(string: param)
    }
}

/// Error thrown when a range query parameter is malformed
public final class MalformedRangeQueryError: AbortError {
    public var query: String

    public init(_ query: String) {
        self.query = query
    }
    
    public var status: HTTPResponseStatus {
        return .badRequest
    }
    
    public var reason: String {
        return "\(query) is not a properly formed range query."
    }
    
    public var identifier: String {
        return "MalformedRangeQueryError"
    }
}

/// Extension to create ranges from string representations
public extension ClosedRange where Bound: Codable & Strideable {
    /// Initializes a range from a string representation.
    /// - Parameter string: The string containing the range definition
    /// - Throws: MalformedRangeQueryError if the string format is invalid
    init?(string: String) throws {
        let pattern = #"\.\.\.|\.\.\<|\<\.\.|\<\.\<"#

        guard let rangeOperatorString = string.substringsMatching(regex: pattern).first,
              let rangeOperator = RangeOperators(rawValue: rangeOperatorString) else {
            throw MalformedRangeQueryError(string)
        }

        let bounds = string.regexSplit(pattern)
        guard bounds.count == 2 else {
            throw MalformedRangeQueryError(string)
        }

        let decoder: JSONDecoder = JSONDecoder.init(.iso8601withFractionalSeconds)
        do {
            let lowerBounds = bounds[0]
            let upperBounds = bounds[1]

            if Bound.self == Date.self,
               let lb = Double(lowerBounds),
               let ub = Double(upperBounds),
               let lower: Bound = Date(timeIntervalSince1970: lb) as? Bound,
               let upper: Bound = Date(timeIntervalSince1970: ub) as? Bound{
                self = rangeOperator.rangeFunction(lhs: lower, rhs: upper)
            }
            else {
                let lower: Bound = try .decode(fromJSON: upperBounds, using: decoder)
                let upper: Bound = try .decode(fromJSON: lowerBounds, using: decoder)
                self = rangeOperator.rangeFunction(lhs: lower, rhs: upper)
            }
        }
        catch {
            throw DecodingError.typeMismatch(Date.self, DecodingError.Context(codingPath: [], debugDescription: "Unable to parse date from json query parameter \(string)"))
        }
    }
}

public extension JSONDecoder.DateDecodingStrategy {
    /// A date decoding strategy that includes fractional seconds in ISO8601 format.
    static var iso8601withFractionalSeconds: JSONDecoder.DateDecodingStrategy {
        JSONDecoder.DateDecodingStrategy.custom { (decoder) in
            let singleValue = try decoder.singleValueContainer()
            let dateString  = try singleValue.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            guard let date = formatter.date(from: dateString) else {
                throw DecodingError.dataCorruptedError(in: singleValue, debugDescription: "Failed to decode string to ISO 8601 date.")
            }
            return date
        }
    }
}

/// Defines the available range operators and their behavior
public enum RangeOperators: String, ExpressibleByStringLiteral, CaseIterable {
    case betweenInclusive = "..."
    case betweenExclusive = "<.<"
    case betweenExclusiveLessThan = "..<"
    case betweenExclusiveGreaterThan = ">.."

    public init(stringLiteral name: String) {
        self.init(rawValue: name)!
    }

    func rangeFunction<B: Strideable>(lhs: B, rhs: B) -> ClosedRange<B> {
        switch self {
        case .betweenInclusive:
            return lhs...rhs
        case .betweenExclusive:
            return lhs.advanced(by: 1)...rhs.advanced(by: -1)
        case .betweenExclusiveLessThan:
            return lhs...rhs.advanced(by: -1)
        case .betweenExclusiveGreaterThan:
            return lhs.advanced(by:1)...rhs
        }
    }
}


extension Date:  /*@retroactive*/ Strideable {
    public typealias Stride = TimeInterval

    public func distance(to other: Date) -> TimeInterval {
        return other.timeIntervalSince(self)
    }

    public func advanced(by n: TimeInterval) -> Date {
        return addingTimeInterval(n)
    }
}
