import Foundation
import SQLite

// tables
fileprivate let interlinearTable = Table("interlinear")
fileprivate let strongsTable = Table("strongs")
// columns
fileprivate let origSort = Expression<Double>("orig_sort")
fileprivate let origText = Expression<String>("orig_text")
fileprivate let bsbSort = Expression<Double>("bsb_sort")
fileprivate let bsbText = Expression<String>("bsb_text")
fileprivate let langCode = Expression<String>("lang_code")
fileprivate let bookId = Expression<Int>("book")
fileprivate let chapterId = Expression<Int>("chapter")
fileprivate let verseId = Expression<Int>("verse")
fileprivate let translit = Expression<String>("transliteration")
fileprivate let parsing = Expression<String>("parsing")
fileprivate let parsingFull = Expression<String>("parsing_full")
fileprivate let strongsId = Expression<Int>("strongs")
fileprivate let strongsNumId = Expression<Int>("num")
fileprivate let strongsText = Expression<Int>("text")

fileprivate func sortParts(_ parts: [VersePart], isOrig: Bool) -> [VersePart] {
    return parts.sorted { lhs, rhs in
        return isOrig ? lhs.origSort < rhs.origSort : lhs.sort < rhs.sort
    }
}

public struct BereanBibleManager {
    let db: Connection
    
    public init() {
        let path = Bundle.module.path(forResource: "bsb", ofType: "db")!
        db = try! Connection(path, readonly: true)
    }

    /// Returns the text for the specified verse range, or the given chapter
    /// - parameters:
    ///     - book: The book ID
    ///     - chapter: The chapter ID
    ///     - verseRange: The verse range of the text
    ///     - isOrig: Indicates if the original language or the BSB translation (default) is used
    public func text(book: Int, chapter: Int, verseRange: Range<Int>?, isOrig: Bool = false) -> String {
        let lines = lines(book: book, chapter: chapter, verseRange: verseRange, isOrig: isOrig)
        
        let fullText = NSMutableString()
        for line in lines {
            fullText.append(line + " ")
        }
        
        return (fullText as String).trimmingCharacters(in: .whitespaces)
    }
    
    /// Returns the lines of text for the specified verse range, or the given chapter for the original language or the BSB translation (default)
    /// - parameters:
    ///     - book: The book ID
    ///     - chapter: The chapter ID
    ///     - verseRange: The verse range of the text
    ///     - isOrig: Indicates if the original language or the BSB translation (default) is used
    public func lines(book: Int, chapter: Int, verseRange: Range<Int>?, isOrig: Bool = false) -> [String] {
        let verses = verses(book: book, chapter: chapter, verseRange: verseRange, isOrig: isOrig)
        
        // collect all text from all the rows/verses
        var textParts: [String] = []
        for verse in verses {
            for part in verse.parts {
                let text = isOrig ? part.origText : part.text
                textParts.append(text)
            }
        }
        
        return textParts
    }
    
    private func getVersePart(from row: Row) -> VersePart {
        return VersePart(
            origSort: try! row.get(origSort),
            origText: try! row.get(origText),
            sort: try! row.get(bsbSort),
            text: try! row.get(bsbText),
            bookId: try! row.get(bookId),
            chapter: try! row.get(chapterId),
            verse: try! row.get(verseId),
            transliteration: try! row.get(translit),
            parsing: try! row.get(parsing),
            parsingFull: try! row.get(parsingFull),
            strongs: try! row.get(strongsId),
            langCode: try! row.get(langCode)
        )
    }
    
    /// Returns the verses for the specified book, chapter and verse range
    /// - parameters:
    ///     - book: The book ID
    ///     - chapter: The chapter ID
    ///     - verseRange: The verse range of the text
    ///     - isOrig: Indicates if the original language or the BSB translation (default) is used
    public func verses(book: Int, chapter: Int, verseRange: Range<Int>?, isOrig: Bool = false) -> [Verse] {
        // select the verses
        var table = interlinearTable.filter(bookId == book).filter(chapterId == chapter)
        if let range = verseRange {
            if range.startIndex == range.endIndex {
                table = table.filter(verseId == range.startIndex)
            } else {
                table = table.filter(verseId >= range.startIndex).filter(verseId < range.endIndex)
            }
        }
        
        let query = try? db.prepare(table)
        guard let query = query else {
            return []
        }
        
        var verses: [Verse] = []
        var parts: [VersePart] = []
        
        // get the verses
        var lastVerseId = 0
        for row in query {
            let verseId = try! row.get(verseId)
            
            // wait until the parts for the first verse in the range are aggregated
            if lastVerseId == 0 {
                lastVerseId = verseId
            }
            
            // when the verse changes, store the parts
            if verseId != lastVerseId {
                verses.append(Verse(bookId: book, chapter: chapter, verse: lastVerseId, parts: sortParts(parts, isOrig: isOrig)))
                parts = []
                lastVerseId = verseId
            }
            
            parts.append(getVersePart(from: row))
        }
        
        // store the last parts
        verses.append(Verse(bookId: book, chapter: chapter, verse: lastVerseId, parts: sortParts(parts, isOrig: isOrig)))
        return verses
    }
}

/// Represents a single verse and its information
public struct Verse {
    var bookId: Int
    var chapter: Int
    var verse: Int
    var parts: [VersePart]
    var langCode: String
    
    init(bookId: Int, chapter: Int, verse: Int, parts: [VersePart]) {
        self.bookId = bookId
        self.chapter = chapter
        self.verse = verse
        self.parts = parts
        self.langCode = parts.first!.langCode
    }
    
    /// Sorts the parts, based on language. Sorts in-place.
    /// - Parameter asOrignal: Indicates that the sort should occur as the original language would sort it
    /// - Returns: The sorted parts.
    mutating func sortParts(asOriginal: Bool) -> [VersePart] {
        parts = BereanBible.sortParts(parts, isOrig: asOriginal)
        return parts
    }
}

/// Represents a part of a single verse
public struct VersePart {
    var origSort: Double
    var origText: String
    var sort: Double
    var text: String
    var bookId: Int
    var chapter: Int
    var verse: Int
    var transliteration: String
    var parsing: String
    var parsingFull: String
    var strongs: Int
    /// Original language code H = Hebrew/Aramaic and G = Greek
    var langCode: String
}
