//
//  FoundationExtensions.swift
//  FluentExtensions
//
//  Created by Brian Strobach on 5/30/18.
//

import Foundation

extension Collection{
	func indexed<Key>(extractKey: @escaping (Element) throws -> Key) throws -> [Key:Element] where Key : Hashable {
		var dictionary: [Key: Element] = [:]
		try forEach { (value) in
			dictionary[try extractKey(value)] = value
		}
		return dictionary
	}
}

extension Range where Bound == Int{

	func randomSubrange(_ size: Int) -> Range<Int>{
		guard size <= self.count else { return self }
		let clampedSize = (0...count).clamp(value: size)
		let maxLowerBound = lowerBound + count - clampedSize
		guard let randomLowerBound = (lowerBound...maxLowerBound).random() else { return self }
		return Range<Int>(randomLowerBound...randomLowerBound + size - 1)
	}
}

extension ClosedRange where Bound == Int{

	func random() -> Int? {
		return Range<Int>(self).random()
	}

	func randomSubrange(_ size: Int) -> ClosedRange<Int>{
		return ClosedRange<Int>(Range<Int>(self).randomSubrange(size))
	}
}

extension RandomAccessCollection {
	func random() -> Iterator.Element? {
		guard let index = randomIndex() else { return nil }
		return self[index]
	}

	func randomIndex() -> Index? {
		guard !isEmpty else { return nil }
		let offset = Int.random(in: 0..<count)
		let i = index(startIndex, offsetBy: numericCast(offset))
		return i
	}
}

extension ClosedRange {
	func clamp(value : Bound) -> Bound {
		return lowerBound > value ? lowerBound
			: upperBound < value ? upperBound
			: value
	}
}
