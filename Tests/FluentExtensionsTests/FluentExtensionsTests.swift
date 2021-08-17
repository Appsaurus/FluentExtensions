import XCTVapor

@testable import FluentExtensions

final class FluentExtensionsTests: XCTestCase {

	static var allTests = [
		("testRandomRangeElement", testRandomRangeElement),
		("testRandomSubrange", testRandomSubrange)
	]

	let ranges: [ClosedRange<Int>] = [-1000 ... -500, -500...0, -250...250]
	let iterations: Int = 10000

    func testRandomRangeElement() throws {
		for range in ranges{
			for _ in 0...iterations{
				XCTAssert(range.contains(range.random()!))
			}
		}
    }

	func testRandomSubrange() throws{

		for range in ranges{
			for _ in 0...iterations{
				let subrangeSize = 10
				let subrange = range.randomSubrange(subrangeSize)
				XCTAssertEqual(subrange.count, subrangeSize)
				let clamped = subrange.clamped(to: range)
				XCTAssertEqual(clamped.count, subrangeSize)
			}
		}
	}

    func testPropertyName() throws {
//        let app = Application(.testing)
//        defer { app.shutdown() }
//        try configure(app)
    }
}


