import XCTest
@testable import BereanBible

let Book = (
    Genesis: 1,
    John: 43,
    ThirdJohn: 64
)

final class BereanBibleTests: XCTestCase {
    var manager: BereanBibleManager {
        return BereanBibleManager.shared
    }
    
    func testOTVerse() throws {
        // english
        var text = manager.text(bookID: Book.Genesis, chapter: 1, verseRange: Range(uncheckedBounds: (1, 1)))
        
        XCTAssertEqual(text, "In the beginning God - created the heavens and the earth")
        
        // hebrew
        text = manager.text(bookID: Book.Genesis, chapter: 1, verseRange: Range(uncheckedBounds: (1, 1)), isOrig: true)
        
        XCTAssertEqual(text, "בְּרֵאשִׁ֖ית בָּרָ֣א אֱלֹהִ֑ים אֵ֥ת הַשָּׁמַ֖יִם וְאֵ֥ת הָאָֽרֶץ׃")
    }
    
    func testNTVerse() throws {
        // english
        var text = manager.text(bookID: Book.John, chapter: 1, verseRange: Range(uncheckedBounds: (1, 1)))
        
        XCTAssertEqual(text, "In [the] beginning was the Word and the Word was with - God and the Word was God")
        
        // greek
        text = manager.text(bookID: Book.John, chapter: 1, verseRange: Range(uncheckedBounds: (1, 1)), isOrig: true)
        
        XCTAssertEqual(text, "Ἐν ἀρχῇ ἦν ὁ Λόγος καὶ ὁ Λόγος ἦν πρὸς τὸν Θεόν καὶ Θεὸς ἦν ὁ Λόγος")
    }
    
    func testSmallChapter() throws {
        let verses = manager.verses(bookID: Book.ThirdJohn, chapter: 1)
        
        XCTAssertEqual(verses.count, 14, "Wrong verse count for 3 John")
    }
    
    func testNTVerseParts() throws {
        let verses = manager.verses(bookID: Book.John, chapter: 1, verseRange: Range(uncheckedBounds: (1, 3)))
        
        XCTAssertEqual(verses.count, 3, "Wrong verse count for John 1:1-3")
        
        let verse3 = verses.last!
        let text = BereanBibleManager.text(from: [verse3])
        
        XCTAssertEqual(text, "Through Him all things were made and without Him nothing ... was made that has been made", "Wrong verse text")
    }
    
    func testEdgeCases() throws {
        // has a verse part with no Strong's number
        let verses = manager.verses(bookID: Book.Genesis, chapter: 1, verseRange: Range(uncheckedBounds: (11, 11)))
        
        XCTAssertEqual(verses.count, 1, "wrong verse count")
        
        let parts = verses.first!.parts
        // find the verse
        let noStrongsPart = parts.filter({ $0.strongs == 0 }).first
        
        XCTAssertEqual(noStrongsPart?.strongs, 0, "has a strong value")
    }
}
