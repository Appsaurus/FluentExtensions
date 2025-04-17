//
//  IDProperty+String.swift
//  
//
//  Created by Brian Strobach on 9/2/21.
//

import Fluent

public extension IDProperty {
    /// Converts the ID value to its string representation
    /// - Returns: A string representation of the ID value
    /// - Note: Supports String, Int, and UUID ID types
    func toString() -> String {
        switch self.value {
        case let stringType as String:
            return stringType
        case let intID as Int:
            return "\(intID)"
        case let uuidID as UUID:
            return uuidID.uuidString
        default:
            assertionFailure()
            return ""
        }
    }
}
