//
//  RefactorIntoBaseSwiftLibrary.swift
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

	func random() -> Int? {
		return CountableClosedRange<Int>(self).random()
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

extension CountableClosedRange where Bound == Int{
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
		let offset = Random.int(max: count)
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

//TODO: Remove this once Swift 4.2 unifies Random API
public class Random{

	#if os(Linux)
	static var initialized = false
	#endif

	static public func int(range: CountableClosedRange<Int> ) -> Int{
		var offset = 0

		if range.lowerBound < 0   // allow negative ranges
		{
			offset = abs(range.lowerBound)
		}

		let min = range.lowerBound + offset
		let max = range.upperBound   + offset

		#if os(Linux)
		seedRandom()
		return Int((random() % max) + min) - offset
		#else
		return Int(UInt32(min) + arc4random_uniform(UInt32(max) - UInt32(min))) - offset
		#endif

	}
	static public func int(max: Int) -> Int {
		#if os(Linux)
		seedRandom()
		return Int(random() % max)
		#else
		return Int(arc4random_uniform(UInt32(max)))
		#endif
	}


	static public func int() -> Int{
		#if os(Linux)
		seedRandom()
		return Int(random())
		#else
		return Int(arc4random())
		#endif
	}

	#if os(Linux)
	static public func seedRandom(){
		if !Random.initialized {
			srandom(UInt32(time(nil)))
			Random.initialized = true
		}
	}
	#endif
}
