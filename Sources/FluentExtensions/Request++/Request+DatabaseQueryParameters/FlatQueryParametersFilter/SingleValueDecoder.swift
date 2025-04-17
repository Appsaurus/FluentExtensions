//
//  SingleValueDecoder.swift
//
//
//  Created by Brian Strobach on 9/7/21.
//

/// A specialized decoder for extracting single values from nested data structures.
///
/// This decoder provides functionality to decode individual values from deeply nested structures
/// using an array of coding keys that represent the path to the desired value.
///
/// ## Usage
/// ```swift
/// let decoder = SingleValueDecoder(from: data)
/// let value: String = try decoder.get(at: ["user", "profile", "name"])
/// ```
internal struct SingleValueDecoder: Decodable {
    let decoder: Decoder
    
    init(from decoder: Decoder) throws {
        self.decoder = decoder
    }

    /// Retrieves a value at the specified key path in the decoded data.
    ///
    /// - Parameter keyPath: An array of `CodingKey`s representing the path to the desired value.
    /// - Returns: The decoded value of type `D` at the specified key path.
    /// - Throws: Decoding errors if the path is invalid or the value cannot be decoded.
    internal func get<D>(at keyPath: [CodingKey]) throws -> D
        where D: Decodable
    {
        return try self.get(at: keyPath.map { .key($0.stringValue) })
    }

    /// Internal implementation of the value retrieval logic.
    ///
    /// Traverses the decoded data structure following the provided key path and extracts
    /// the value at the specified location.
    ///
    /// - Parameters:
    ///   - keyPath: An array of `BasicCodingKey`s representing the path to the desired value.
    /// - Returns: The decoded value of type `D`.
    /// - Throws: Decoding errors if the path is invalid or the value cannot be decoded.
    private func get<D>(at keyPath: [BasicCodingKey]) throws -> D where D: Decodable {
        let unwrapper = self
        var state = try ContainerState.keyed(unwrapper.decoder.container(keyedBy: BasicCodingKey.self))

        var keys = Array(keyPath.reversed())
        if keys.count == 0 {
            return try unwrapper.decoder.singleValueContainer().decode(D.self)
        }

        while let key = keys.popLast() {
            switch keys.count {
            case 0:
                switch state {
                case .keyed(let keyed):
                    return try keyed.decode(D.self, forKey: key)
                case .unkeyed(var unkeyed):
                    return try unkeyed.nestedContainer(keyedBy: BasicCodingKey.self)
                        .decode(D.self, forKey: key)
                }
            case 1...:
                let next = keys.last!
                if let index = next.intValue {
                    switch state {
                    case .keyed(let keyed):
                        var new = try keyed.nestedUnkeyedContainer(forKey: key)
                        state = try .unkeyed(new.skip(to: index))
                    case .unkeyed(var unkeyed):
                        var new = try unkeyed.nestedUnkeyedContainer()
                        state = try .unkeyed(new.skip(to: index))
                    }
                } else {
                    switch state {
                    case .keyed(let keyed):
                        state = try .keyed(keyed.nestedContainer(keyedBy: BasicCodingKey.self, forKey: key))
                    case .unkeyed(var unkeyed):
                        state = try .keyed(unkeyed.nestedContainer(keyedBy: BasicCodingKey.self))
                    }
                }
            default: fatalError("Unexpected negative key count")
            }
        }
        fatalError("`while let key = keys.popLast()` should never fallthrough")
    }
}

/// Represents the current state of container traversal during decoding.
private enum ContainerState {
    case keyed(KeyedDecodingContainer<BasicCodingKey>)
    case unkeyed(UnkeyedDecodingContainer)
}

private extension UnkeyedDecodingContainer {
    /// Advances the container to a specific index.
    ///
    /// - Parameter count: The number of elements to skip.
    /// - Returns: The container positioned at the desired index.
    /// - Throws: Decoding errors if the skip operation fails.
    mutating func skip(to count: Int) throws -> UnkeyedDecodingContainer {
        for _ in 0..<count {
            _ = try nestedContainer(keyedBy: BasicCodingKey.self)
        }
        return self
    }
}
