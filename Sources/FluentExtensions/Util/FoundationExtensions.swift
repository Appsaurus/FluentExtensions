//
//  FoundationExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 5/30/18.
//

import Foundation

extension Collection {
    /// Transforms a collection into a dictionary by extracting a hashable key from each element.
    /// - Parameter extractKey: A closure that extracts a hashable key from an element.
    /// - Returns: A dictionary where the keys are extracted using the provided closure and values are the original elements.
    /// - Throws: Rethrows any errors thrown by the extractKey closure.
    ///
    /// Example:
    /// ```swift
    /// let users = [User(id: 1), User(id: 2)]
    /// let dictionary = try users.indexed { $0.id } // [1: User(id: 1), 2: User(id: 2)]
    /// ```
    func indexed<Key>(extractKey: @escaping (Element) throws -> Key) throws -> [Key:Element] where Key : Hashable {
        var dictionary: [Key: Element] = [:]
        try forEach { (value) in
            dictionary[try extractKey(value)] = value
        }
        return dictionary
    }
}

extension Range where Bound == Int {
    /// Creates a random subrange of specified size within the current range.
    /// - Parameter size: The desired size of the subrange.
    /// - Returns: A new range of the specified size, or the original range if the requested size is larger than the range.
    ///
    /// The function ensures that:
    /// 1. The subrange size doesn't exceed the original range size
    /// 2. The subrange maintains the sequential order of the original range
    func randomSubrange(_ size: Int) -> Range<Int> {
        guard size <= self.count else { return self }
        let clampedSize = (0...count).clamp(value: size)
        let maxLowerBound = lowerBound + count - clampedSize
        guard let randomLowerBound = (lowerBound...maxLowerBound).random() else { return self }
        return Range<Int>(randomLowerBound...randomLowerBound + size - 1)
    }
}

extension ClosedRange where Bound == Int {
    /// Returns a random integer within the closed range.
    /// - Returns: A random integer within the range, or nil if the range is invalid.
    func random() -> Int? {
        return Range<Int>(self).random()
    }

    /// Creates a random subrange of specified size within the current closed range.
    /// - Parameter size: The desired size of the subrange.
    /// - Returns: A closed range of the specified size.
    func randomSubrange(_ size: Int) -> ClosedRange<Int> {
        return ClosedRange<Int>(Range<Int>(self).randomSubrange(size))
    }
}

extension RandomAccessCollection {
    /// Returns a random element from the collection.
    /// - Returns: A random element, or nil if the collection is empty.
    func random() -> Iterator.Element? {
        guard let index = randomIndex() else { return nil }
        return self[index]
    }

    /// Returns a random valid index from the collection.
    /// - Returns: A random index, or nil if the collection is empty.
    func randomIndex() -> Index? {
        guard !isEmpty else { return nil }
        let offset = Int.random(in: 0..<count)
        let i = index(startIndex, offsetBy: numericCast(offset))
        return i
    }
}

extension ClosedRange {
    /// Clamps a value to ensure it falls within the range.
    /// - Parameter value: The value to clamp.
    /// - Returns: The value if it's within the range, the lower bound if it's below, or the upper bound if it's above.
    func clamp(value: Bound) -> Bound {
        return lowerBound > value ? lowerBound
            : upperBound < value ? upperBound
            : value
    }
}
