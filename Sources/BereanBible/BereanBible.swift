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

let dbName = "bsb-interlinear"

fileprivate func sortParts(_ parts: [VersePart], isOrig: Bool) -> [VersePart] {
    return parts.sorted { lhs, rhs in
        return isOrig ? lhs.origSort < rhs.origSort : lhs.sort < rhs.sort
    }
}

public enum BereanBibleError: Error {
    case notFound(message: String)
}

public struct BereanBibleManager {
    /// Shared bible manager
    public static let shared = try! BereanBibleManager()
    let db: Connection
    
    // MARK: - Helpers
    
    /// Returns the text for the given verse parts
    public static func line(from parts: [VersePart], isOrig: Bool = false) -> String {
        let lineText = NSMutableString()
        
        for (idx, part) in parts.enumerated() {
            if idx != 0 {
                lineText.append(" ")
            }
            
            let text = isOrig ? part.origText : part.text
            lineText.append(text)
        }
        
        return lineText as String
    }
    
    /// Returns the lines from the specified verses
    public static func lines(from verses: [Verse], isOrig: Bool = false) -> [String] {
        // collect all text lines from all the verses
        var textParts: [String] = []
        for verse in verses {
            textParts.append(Self.line(from: verse.parts, isOrig: isOrig))
        }
        
        return textParts
    }
    
    /// Returns the text for the given verses
    public static func text(from verses: [Verse], isOrig: Bool = false) -> String {
        let lines = Self.lines(from: verses, isOrig: isOrig)
        let text = NSMutableString()
        
        for (idx, line) in lines.enumerated() {
            if idx != 0 {
                text.append(" ")
            }
            
            text.append(line)
        }
        
        return text as String
    }
    
    // MARK: - Initializer
    
    public init() throws {
        if let path = Bundle.module.path(forResource: dbName, ofType: "db") ?? Bundle.main.path(forResource: dbName, ofType: "db") {
            db = try! Connection(path, readonly: true)
        } else {
            throw BereanBibleError.notFound(message: "Unable to find the bible database: \(dbName).db")
        }
    }
    
    // MARK: - Main Operations

    /// Returns the text for the specified verse range, or the given chapter
    /// - parameters:
    ///     - bookID: The book ID
    ///     - chapter: The chapter ID
    ///     - verseRange: The verse range of the text
    ///     - isOrig: Indicates if the original language or the BSB translation (default) is used
    public func text(bookID: Int, chapter: Int, verseRange: Range<Int>?, isOrig: Bool = false) -> String {
        let verses = verses(bookID: bookID, chapter: chapter, verseRange: verseRange, isOrig: isOrig)
        return Self.text(from: verses, isOrig: isOrig)
    }
    
    /// Returns the lines of text for the specified verse range, or the given chapter for the original language or the BSB translation (default)
    /// - parameters:
    ///     - bookID: The book ID
    ///     - chapter: The chapter ID
    ///     - verseRange: The verse range of the text
    ///     - isOrig: Indicates if the original language or the BSB translation (default) is used
    public func lines(bookID: Int, chapter: Int, verseRange: Range<Int>?, isOrig: Bool = false) -> [String] {
        let verses = verses(bookID: bookID, chapter: chapter, verseRange: verseRange, isOrig: isOrig)
        return Self.lines(from: verses, isOrig: isOrig)
    }
    
    /// Returns the verses for the specified book, chapter and verse range
    /// - parameters:
    ///     - bookID: The book ID
    ///     - chapter: The chapter ID
    ///     - verseRange: The verse range of the text, or nil (default) for all chapter verses
    ///     - isOrig: Indicates if the original language or the BSB translation (default) is used
    public func verses(bookID: Int, chapter: Int, verseRange: Range<Int>? = nil, isOrig: Bool = false) -> [Verse] {
        // select the verses
        var table = interlinearTable.filter(bookId == bookID).filter(chapterId == chapter)
        if let range = verseRange {
            if range.startIndex == range.endIndex {
                table = table.filter(verseId == range.startIndex)
            } else {
                table = table.filter(verseId >= range.startIndex).filter(verseId <= range.endIndex)
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
                verses.append(Verse(bookID: bookID, chapter: chapter, verse: lastVerseId, parts: sortParts(parts, isOrig: isOrig)))
                parts = []
                lastVerseId = verseId
            }
            
            parts.append(getVersePart(from: row))
        }
        
        // store the last parts
        verses.append(Verse(bookID: bookID, chapter: chapter, verse: lastVerseId, parts: sortParts(parts, isOrig: isOrig)))
        return verses
    }
    
    // MARK: - Misc
    
    private func getVersePart(from row: Row) -> VersePart {
        return VersePart(
            origSort: try! row.get(origSort),
            origText: try! row.get(origText),
            sort: try! row.get(bsbSort),
            text: try! row.get(bsbText),
            bookID: try! row.get(bookId),
            chapter: try! row.get(chapterId),
            verse: try! row.get(verseId),
            transliteration: try! row.get(translit),
            parsing: try! row.get(parsing),
            parsingFull: try! row.get(parsingFull),
            strongs: try! row.get(strongsId),
            langCode: try! row.get(langCode)
        )
    }
    
}

/// Represents a single verse and its information
public struct Verse {
    var bookID: Int
    var chapter: Int
    var verse: Int
    var parts: [VersePart]
    var langCode: String
    
    init(bookID: Int, chapter: Int, verse: Int, parts: [VersePart]) {
        self.bookID = bookID
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
    var bookID: Int
    /// Chapter number
    var chapter: Int
    /// Verse number
    var verse: Int
    var transliteration: String
    var parsing: String
    var parsingFull: String
    var strongs: Int
    /// Original language code H = Hebrew/Aramaic and G = Greek
    var langCode: String
}
