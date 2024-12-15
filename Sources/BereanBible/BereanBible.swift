import Foundation
import SQLite

typealias SQLExpression = SQLite.Expression

fileprivate let DBName = "bsb-interlinear"

// tables
fileprivate let interlinearTable = Table("interlinear")
//fileprivate let strongsTable = Table("strongs")
// interlinear table columns
fileprivate let col_orig_sort = SQLExpression<Double>("orig_sort")
fileprivate let col_orig_text = SQLExpression<String>("orig_text")
fileprivate let col_bsb_sort = SQLExpression<Double>("bsb_sort")
fileprivate let col_bsb_text = SQLExpression<String>("bsb_text")
fileprivate let col_lang_code = SQLExpression<String>("lang_code")
fileprivate let col_book_id = SQLExpression<Int>("book_id")
fileprivate let col_chapter = SQLExpression<Int>("chapter")
fileprivate let col_verse = SQLExpression<Int>("verse")
fileprivate let col_transliteration = SQLExpression<String>("transliteration")
fileprivate let col_parsing = SQLExpression<String>("parsing")
fileprivate let col_parsing_full = SQLExpression<String>("parsing_full")
fileprivate let col_strongs = SQLExpression<Int?>("strongs")
// strongs table colums
//fileprivate let strongsNumId = SQLExpression<Int>("num")
//fileprivate let strongsText = SQLExpression<String>("text")

fileprivate func sortedParts(_ parts: [VersePart], isOrig: Bool) -> [VersePart] {
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
        var lineText = ""
        
        for (idx, part) in parts.enumerated() {
            if idx != 0 {
                lineText.append(" ")
            }
            
            let text = isOrig ? part.origText : part.text
            lineText.append(text)
        }
        
        return lineText
    }
    
    private static func eachVerse(from verses: [Verse], handler: (Int, Verse) -> Void) {
        for (idx, verse) in verses.enumerated() {
            handler(idx, verse)
        }
    }
    
    /// Returns the lines from the specified verses
    public static func lines(from verses: [Verse], isOrig: Bool = false) -> [String] {
        // collect all text lines from all the verses
        var textParts: [String] = []
        eachVerse(from: verses) { (idx, verse) in
            textParts.append(Self.line(from: verse.parts, isOrig: isOrig))
        }
        return textParts
    }
    
    /// Returns the text for the given verses
    public static func text(from verses: [Verse], isOrig: Bool = false) -> String {
        var text = ""
        
        eachVerse(from: verses) { idx, verse in
            let line = Self.line(from: verse.parts, isOrig: isOrig)
            if idx != 0 {
                text.append(" ")
            }
            
            text.append(line)
        }
        
        return text
    }
    
    /// Returns the parts from the specified verses
    public static func parts(from verses: [Verse]) -> [VersePart] {
        return verses.flatMap({ $0.parts })
    }
    
    // MARK: - Initializer
    
    public init() throws {
        if let path = Bundle.module.path(forResource: DBName, ofType: "db") {
            db = try! Connection(path, readonly: true)
        } else {
            throw BereanBibleError.notFound(message: "Unable to find the bible database: \(DBName).db")
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
        var query = interlinearTable.filter(col_book_id == bookID).filter(col_chapter == chapter)
        if let range = verseRange {
            if range.startIndex == range.endIndex {
                query = query.filter(col_verse == range.startIndex)
            } else {
                query = query.filter(col_verse >= range.startIndex).filter(col_verse <= range.endIndex)
            }
        }
        
        guard let results = try? db.prepare(query) else {
            return []
        }
        
        var verses: [Verse] = []
        var parts: [VersePart] = []
        
        // get the verses
        var lastVerseId = 0
        for row in results {
            let verseId = try! row.get(col_verse)
            
            // wait until the parts for the first verse in the range are aggregated
            if lastVerseId == 0 {
                lastVerseId = verseId
            }
            
            // when the verse changes, store the parts
            if verseId != lastVerseId {
                verses.append(Verse(bookID: bookID, chapter: chapter, verse: lastVerseId, parts: sortedParts(parts, isOrig: isOrig)))
                parts = []
                lastVerseId = verseId
            }
            
            parts.append(versePart(from: row))
        }
        
        // store the last parts
        verses.append(Verse(bookID: bookID, chapter: chapter, verse: lastVerseId, parts: sortedParts(parts, isOrig: isOrig)))
        return verses
    }
    
    /// Returns the copyright text
    public func copyright() -> String {
        return "Berean Interlinear Bible, BIB. Public Domain."
    }
    
    /// Returns the strongs lexicon information for the specified part, if available
    private func strongs(from part: VersePart) -> String {
        guard part.strongs > 0 else {
            return ""
        }

        // TODO: parser must be updated
//        let query = strongsTable.where(strongsNumId == part.strongs)
//        
//        guard let results = try? db.prepare(query) else {
//            return ""
//        }
        
        // should only be one row
//        for row in results {
//            return try! row.get(strongsText)
//        }
        return ""
    }
    
    // MARK: - Misc
    
    private func versePart(from row: Row) -> VersePart {
        return VersePart(
            origSort: try! row.get(col_orig_sort),
            origText: try! row.get(col_orig_text),
            sort: try! row.get(col_bsb_sort),
            text: try! row.get(col_bsb_text),
            bookID: try! row.get(col_book_id),
            chapter: try! row.get(col_chapter),
            verse: try! row.get(col_verse),
            transliteration: try! row.get(col_transliteration),
            parsing: try! row.get(col_parsing),
            parsingFull: try! row.get(col_parsing_full),
            strongs: try! row.get(col_strongs) ?? 0,
            langCode: try! row.get(col_lang_code)
        )
    }
    
}

/// Represents a single verse and its information
public struct Verse {
    /// The identifier for the book: 1 = Genesis, 2 = Exodus, etc.
    public let bookID: Int
    /// Chapter number
    public let chapter: Int
    /// Verse number
    public let verse: Int
    /// The parts to the verse, usually each original language's single word
    public let parts: [VersePart]
    /// Original language code: H = Hebrew/Aramaic and G = Greek
    let langCode: String
    
    init(bookID: Int, chapter: Int, verse: Int, parts: [VersePart]) {
        self.bookID = bookID
        self.chapter = chapter
        self.verse = verse
        self.parts = parts
        self.langCode = parts.first!.langCode
    }
}

/// Represents a part of a single verse
public struct VersePart {
    /// The original language sort order for this part
    public let origSort: Double
    /// The original lanuage text
    public let origText: String
    /// The sort order for the translation
    public let sort: Double
    /// The translated text
    public let text: String
    /// The identifier for the book associated with this part: 1 = Genesis, 2 = Exodus, etc.
    public let bookID: Int
    /// Chapter number associated with this part
    public let chapter: Int
    /// Verse number associated with this part
    public let verse: Int
    public let transliteration: String
    /// The abbreviated parsing string
    public let parsing: String
    /// The unabbreviated parsing string
    public let parsingFull: String
    /// The Strongs number
    public let strongs: Int
    /// Original language code: H = Hebrew/Aramaic and G = Greek
    public let langCode: String
}
