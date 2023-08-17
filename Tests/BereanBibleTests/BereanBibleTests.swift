import XCTest
@testable import BereanBible

final class BereanBibleTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(BereanBibleManager().text, "Hello, World!")
    }
}
