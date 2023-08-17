import XCTest
@testable import BereanBible

final class BereanBibleTests: XCTestCase {    
    func testVerse() throws {
        let text = BereanBibleManager().text(book: 1, chapter: 1, verseRange: Range(uncheckedBounds: (1, 1)))
        XCTAssertEqual(text, "In the beginning God - created the heavens and the earth.")
    }
}
