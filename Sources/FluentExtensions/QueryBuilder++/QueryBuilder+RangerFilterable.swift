//
//  QueryBuilder+RangerFilterable.swift
//  
//
//  Created by Brian Strobach on 9/1/21.
//
import FluentKit
import Fluent
import SQLKit

public typealias RangeFilterable = Strideable & Codable

public extension QueryBuilder  {
    @discardableResult
    func filter<P: QueryableProperty>(_ keyPath: KeyPath<Model, P>, to range: Range<P.Value>) -> Self where P.Value: Strideable {
        return group(.and) {
            $0.filter(keyPath >= range.lowerBound)
            $0.filter(keyPath <= range.upperBound)
        }
    }
//    @discardableResult
//    func filter<V: QueryableProperty>(_ keyPath: KeyPath<Model, V?>, to range: Range<V.Value>) -> Self {
//        return group(.and) {
//            $0.filter(keyPath >= range.lowerBound)
//            $0.filter(keyPath <= range.upperBound)
//        }
//    }
    @discardableResult
    func filter<P: QueryableProperty>(_ keyPath:  KeyPath<Model, P>, to range: ClosedRange<P.Value>) -> Self where P.Value: Strideable {
        return group(.and) {
            $0.filter(keyPath >= range.lowerBound)
            $0.filter(keyPath <= range.upperBound)
        }
    }
//    @discardableResult
//    func filter<P: QueryableProperty>(_ keyPath:  KeyPath<Model, FieldProperty<Model, V?>>, to range: ClosedRange<V>) -> Self {
//        return group(.and) {
//            $0.filter(keyPath >= range.lowerBound)
//            $0.filter(keyPath <= range.upperBound)
//        }
//    }

//    @discardableResult
//    func filter<P: QueryableProperty>(_ keyPath: KeyPath<Model, P>, toRangeAt parameter: String, on request: Request) -> Self where P.Value: Strideable {
//        if let param = request.query[String.self, at: parameter],
//           let range = try? ClosedRange<P.Value>(string: param) {
//            filter(keyPath, to: range)
//        }
//        return self
//    }

    @discardableResult
    func filter<P: QueryableProperty>(_ keyPath: KeyPath<Model, P>, toRangeAt parameter: String, on request: Request) -> Self where P.Value: Strideable {
        let logFailedParse = {
            let stringParam: String? = try? request.query.get(at: parameter)
            request.logger.info("Failed to decode range query parameter for parameter \(parameter). Found \(String(describing: stringParam))")
        }
        do {
            guard let range: ClosedRange<P.Value> = try request.query.rangeThrowing(at: parameter) else {
                logFailedParse()
                return self
            }
            request.logger.info("Decoded range query parameter: \(range) for parameter \(parameter)")
            filter(keyPath, to: range)
        }
        catch {
            logFailedParse()
            request.logger.error("Failed to decode range query parameter with error: \(error.localizedDescription)")
        }
        return self
    }


}

public extension URLQueryContainer {
    func range<V: RangeFilterable>(at parameter: String) -> ClosedRange<V>? {
        return try? rangeThrowing(at: parameter)
    }

    func rangeThrowing<V: RangeFilterable>(at parameter: String) throws -> ClosedRange<V>? {
        guard let param = self[String.self, at: parameter] else {
            return nil
        }
        return try ClosedRange<V>(string: param)
    }
}


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
public extension ClosedRange where Bound: Codable & Strideable {

    init?(string: String) throws {
        let pattern = #"\.\.\.|\.\.\<|\<\.\.|\<\.\<"#
//        let pattern = RangeOperators.allCases.map({
//            return $0.rawValue.charactersArray.map({String($0)}).joined(separator: #"\"#)
//        }).joined(separator: "|")

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

    /// The strategy that formats dates according to the ISO 8601 standard.
    /// - Note: This includes the fractional seconds, unlike the standard `.iso8601`, which fails to decode those.
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


fileprivate extension String {
    func substringsMatching(regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self,
                                        range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    func regexSplit(_ pattern: String) -> [String] {
        do {
            let regex: NSRegularExpression = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let stop: String = "&උටෟ#ߤჀ"
            let modifiedString: String = regex.stringByReplacingMatches(in: self, options: NSRegularExpression.MatchingOptions(),
                                                                        range: NSRange(location: 0, length: self.count), withTemplate: stop)
            return modifiedString.components(separatedBy: stop)
        } catch {
            return []
        }
    }

}
