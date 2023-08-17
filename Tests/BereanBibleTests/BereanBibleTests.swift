import XCTest
@testable import BereanBible

final class BereanBibleTests: XCTestCase {    
    func testOTVerse() throws {
        // english
        var text = BereanBibleManager().text(book: 1, chapter: 1, verseRange: Range(uncheckedBounds: (1, 1)))
        XCTAssertEqual(text, "In the beginning God - created the heavens and the earth.")
        
        // hebrew
        text = BereanBibleManager().text(book: 1, chapter: 1, verseRange: Range(uncheckedBounds: (1, 1)), isOrig: true)
        XCTAssertEqual(text, "בְּרֵאשִׁ֖ית אֱלֹהִ֑ים אֵ֥ת בָּרָ֣א הַשָּׁמַ֖יִם וְאֵ֥ת הָאָֽרֶץ׃")
    }
    
    func testNTVerse() throws {
        // english
        var text = BereanBibleManager().text(book: 43, chapter: 1, verseRange: Range(uncheckedBounds: (1, 1)))
        XCTAssertEqual(text, "In [the] beginning was the Word, and the Word was with - God, and the Word was God.")
        
        // hebrew
        text = BereanBibleManager().text(book: 43, chapter: 1, verseRange: Range(uncheckedBounds: (1, 1)), isOrig: true)
        XCTAssertEqual(text, "Ἐν ἀρχῇ ἦν ὁ Λόγος καὶ ὁ Λόγος ἦν πρὸς τὸν Θεόν καὶ ὁ Λόγος ἦν Θεὸς")
    }
}
