//
//  IDProperty+String.swift
//  
//
//  Created by Brian Strobach on 9/2/21.
//

import Fluent

public extension IDProperty{
    func toString() -> String{
        switch self.value{
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
