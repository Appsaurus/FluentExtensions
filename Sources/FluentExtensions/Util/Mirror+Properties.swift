//
//  Mirror+Properties.swift
//
//
//  Created by Brian Strobach on 10/24/21.
//

/// Extends Swift's Mirror type to provide property reflection utilities
extension Mirror {
    /// Returns an array of ``MirroredProperty`` instances representing all named properties of the given instance
    ///
    /// This method uses Swift's runtime reflection to inspect the properties of any object.
    /// Only properties with labels are included in the result.
    ///
    /// - Parameter instance: The object whose properties should be reflected
    /// - Returns: Array of ``MirroredProperty`` containing name and type information for each property
    ///
    /// - Note: Properties without labels (like tuple elements) are ignored
    static func properties(of instance: Any) -> [MirroredProperty] {
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

/// Represents a reflected property with its name and type information
///
/// Used to store metadata about an object's properties obtained through reflection.
public struct MirroredProperty {
    /// The name/label of the property
    public let name: String
    
    /// The runtime type of the property
    public let type: Any.Type
}
