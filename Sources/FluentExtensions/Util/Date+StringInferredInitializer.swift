//
//  Date+StringInferredInitializer.swift
//
//
//  Created by Brian Strobach on 2/24/25.
//

import Foundation

extension Date {
    /// Attempts to create a `Date` instance by inferring the format of a given date string.
    ///
    /// This initializer supports a wide variety of date formats including:
    /// - ISO8601 formats with 'T' separator and 'Z' suffix
    /// - ISO8601 formats with 'T' separator
    /// - Standard datetime formats with space separator
    /// - Unix timestamps
    ///
    /// If the string matches any of the supported formats, the date will be created using that format.
    /// If the string represents a Unix timestamp (numeric value), it will be interpreted as seconds since 1970.
    ///
    /// ```swift
    /// // ISO8601 format
    /// let date1 = Date(string: "2024-02-24T15:30:00Z")
    ///
    /// // Standard format
    /// let date2 = Date(string: "2024-02-24 15:30:00")
    ///
    /// // Unix timestamp
    /// let date3 = Date(string: "1708789800")
    /// ```
    ///
    /// - Parameter string: A string representing a date in any of the supported formats
    /// - Returns: A new Date instance if the string can be parsed, nil otherwise
    public init?(string: String) {
        let formats = [
            // ISO8601 formats with T separator and Z suffix
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mmZ",
            "yyyy-MM-dd'T'HHZ",
            // ISO8601 formats with T separator
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm",
            "yyyy-MM-dd'T'HH",
            // Original formats
            "yyyy-MM-dd HH:mm:ss.SSSSSS",
            "yyyy-MM-dd HH:mm:ss.SSS",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd HH",
            "yyyy-MM-dd",
            "MM-dd-yyyy HH:mm:ss.SSSSSS",
            "MM-dd-yyyy HH:mm:ss.SSS",
            "MM-dd-yyyy HH:mm:ss",
            "MM-dd-yyyy HH:mm",
            "MM-dd-yyyy HH",
            "MM-dd-yyyy",
            "HH:mm:ss.SSSSSS",
            "HH:mm:ss",
        ]
        
        for format in formats {
            if let date = string.date(withFormat: format) {
                self = date
                return
            }
        }
        
        if let unixTimestamp = Double(string) {
            self = Date(unixTimestamp: unixTimestamp)
            return
        }
        
        return nil
    }
}

public extension JSONDecoder.DateDecodingStrategy {
    /// A custom date decoding strategy that attempts to infer the date format from the string representation.
    ///
    /// This strategy uses the `Date(string:)` initializer to parse date strings in various formats.
    /// It's particularly useful when dealing with APIs that may return dates in inconsistent formats.
    ///
    /// ```swift
    /// let decoder = JSONDecoder()
    /// decoder.dateDecodingStrategy = .inferred
    ///
    /// // Will successfully decode dates in various formats:
    /// // {"date": "2024-02-24T15:30:00Z"}
    /// // {"date": "2024-02-24 15:30:00"}
    /// // {"date": "1708789800"}
    /// ```
    ///
    /// - Throws: `DecodingError.typeMismatch` if the date string cannot be parsed
    static var inferred: JSONDecoder.DateDecodingStrategy {
        return custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            guard let date = Date(string: dateStr) else  {
                throw DecodingError.typeMismatch(Date.self,
                                                 DecodingError.Context(codingPath: decoder.codingPath,
                                                                       debugDescription: "Could not decode string by inferring date format."))
            }
            return date
        })
    }
}
