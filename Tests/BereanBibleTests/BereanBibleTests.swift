import XCTest
@testable import BereanBible

let Book = (
    Genesis: 1,
    John: 43,
    ThirdJohn: 64
)

final class BereanBibleTests: XCTestCase {
    let manager = BereanBibleManager.shared
    
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
    
    func testSmallChapterVerses() throws {
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
    
    func testNormalizedParsingFull() throws {
        let otVerses = manager.verses(bookID: Book.Genesis, chapter: 1, verseRange: Range(uncheckedBounds: (1, 1)))
        let ot2Verses = manager.verses(bookID: Book.Genesis, chapter: 1, verseRange: Range(uncheckedBounds: (2, 2)))
        let ntVerses = manager.verses(bookID: Book.John, chapter: 1, verseRange: Range(uncheckedBounds: (1, 1)))
        
        // ot
        // genesis 1:1
        let otV1 = otVerses.first
        XCTAssertEqual(otV1?.parts[0].normalizedParsingFull(), "preposition b noun feminine singular")
        
        // genesis 1:2
        let ot2V1 = ot2Verses.first
        XCTAssertEqual(ot2V1?.parts[0].normalizedParsingFull(), "conjunctive waw article noun feminine singular")
        
        // nt
        // john 1:1
        let ntV1 = ntVerses.first
        XCTAssertEqual(ntV1?.parts[1].normalizedParsingFull(), "noun dative feminine singular")
        XCTAssertEqual(ntV1?.parts[2].normalizedParsingFull(), "verb imperfect indicative active 3rd person singular")
    }
    
    // MARK: - Objective-C Wrapper Tests
    let bbManager = BBManager.shared
    
    func testOTVerseBB() throws {
        // english
        var text = bbManager.text(bookID: Book.Genesis, chapter: 1, verseRange: NSMakeRange(1, 1), isOrig: false)
        XCTAssertEqual(text, "In the beginning God - created the heavens and the earth")
        
        // hebrew
        text = bbManager.text(bookID: Book.Genesis, chapter: 1, verseRange: NSMakeRange(1, 1), isOrig: true)
        XCTAssertEqual(text, "בְּרֵאשִׁ֖ית בָּרָ֣א אֱלֹהִ֑ים אֵ֥ת הַשָּׁמַ֖יִם וְאֵ֥ת הָאָֽרֶץ׃")
    }
    
    func testNTVerseBB() throws {
        // english
        var text = bbManager.text(bookID: Book.John, chapter: 1, verseRange: NSMakeRange(1, 1), isOrig: false)
        XCTAssertEqual(text, "In [the] beginning was the Word and the Word was with - God and the Word was God")
        
        // greek
        text = bbManager.text(bookID: Book.John, chapter: 1, verseRange: NSMakeRange(1, 1), isOrig: true)
        XCTAssertEqual(text, "Ἐν ἀρχῇ ἦν ὁ Λόγος καὶ ὁ Λόγος ἦν πρὸς τὸν Θεόν καὶ Θεὸς ἦν ὁ Λόγος")
    }
    
    func testSmallChapterVersesBB() throws {
        let verses = bbManager.verses(bookID: Book.ThirdJohn, chapter: 1, isOrig: false)
        XCTAssertEqual(verses.count, 14, "Wrong verse count for 3 John")
    }
    
    func testNTVersePartsBB() throws {
        let verses = bbManager.verses(bookID: Book.John, chapter: 1, verseRange: NSMakeRange(1, 3), isOrig: false)
        XCTAssertEqual(verses.count, 3, "Wrong verse count for John 1:1-3")
        
        let verse3 = verses.last!
        let partsWords = BBManager.text(from: [verse3], isOrig: false)
        XCTAssertEqual(partsWords, "Through Him all things were made and without Him nothing ... was made that has been made", "Wrong verse text")
    }
}
