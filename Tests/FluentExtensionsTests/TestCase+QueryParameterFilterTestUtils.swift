//
//  TestCase+QueryParameterFilterTestUtils.swift
//
//
//  Created by Brian Strobach on 2/21/25.
//

import Foundation

import XCTest
import XCTVapor
import FluentExtensions
import FluentTestModels
import Codability

public extension FluentTestModels.TestCase {
    // Helper function to create filter URL
    func makeFilterURL(basePath: String, _ condition: TestFilterCondition) throws -> String {
        return "\(basePath)?filter=\(try condition.toURLQueryString())"
    }
    
    func getFilteredItems<M: Decodable>(basePath: String, _ condition: TestFilterCondition) async throws -> [M] {
        let response = try await app.sendRequest(.GET, try makeFilterURL(basePath: basePath, condition))
        XCTAssertEqual(response.status, .ok)
        return try response.content.decode(Page<M>.self).items
    }
}

// Helper structures to represent filter conditions
public enum TestFilterCondition: Encodable {
    case field(_ field: String, _ method: String, _ value: Encodable?)
    case and([TestFilterCondition])
    case or([TestFilterCondition])
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .field(let field, let method, let value):
            try container.encode(field, forKey: .field)
            try container.encode(method, forKey: .method)
            if let value {
                try container.encode(value, forKey: .value)
            }
            else {
                try container.encodeNil(forKey: .value)
            }
            
        case .and(let conditions):
            try container.encode(conditions, forKey: .and)
        case .or(let conditions):
            try container.encode(conditions, forKey: .or)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case field, method, value, and, or
    }
    
    
    
    func toURLQueryString() throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = JSONEncoder.DateEncodingStrategy.custom { (date, encoder) in

            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = formatter.string(from: date)            
            var singleEncoder = encoder.singleValueContainer()
            try singleEncoder.encode(dateString)
            
        }

        
        let jsonData = try encoder.encode(self)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        return jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    }
}
