//
//  Date+StringInferredInitializer.swift
//
//
//  Created by Brian Strobach on 2/24/25.
//

import Foundation


extension Date {

    /// Best effort to infer date from string in any format
    /// - Parameter string: Date string in any format
    public init?(string: String) {


        var formats = [
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
