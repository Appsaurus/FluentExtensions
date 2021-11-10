//
//  Mirror+Properties.swift
//  
//
//  Created by Brian Strobach on 10/24/21.
//

extension Mirror {
    static func properties(of instance: Any) -> [MirroredProperty]{
        var props: [MirroredProperty] = []
        for child in Mirror(reflecting: instance).children {
            guard let name = child.label else {
                continue
            }
            props.append(MirroredProperty(name: name, type: type(of: child.value)))
        }
        return props
    }
}

public struct MirroredProperty {
    public let name: String
    public let type: Any.Type
}

