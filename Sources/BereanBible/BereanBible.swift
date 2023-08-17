import Foundation
import SQLite

// tables
let interlinearTable = Table("interlinear")
let strongsTable = Table("strongs")
// columns
let origSort = Expression<Int>("orig_sort")
let origText = Expression<String>("orig_text")
let bsbSort = Expression<Int>("bsb_sort")
let bsbText = Expression<String>("bsb_text")
let langCode = Expression<String>("lang_code")
let bookId = Expression<Int>("book")
let chapterId = Expression<Int>("chapter")
let verseId = Expression<Int>("verse")
let translit = Expression<String>("transliteration")
let parsing = Expression<String>("parsing")
let parsingFull = Expression<String>("parsing_full")
let strongsId = Expression<Int>("strongs")
let strongsNumId = Expression<Int>("num")
let strongsText = Expression<Int>("text")

public struct BereanBibleManager {
    let db: Connection
    
    public init() {
        let path = Bundle.module.path(forResource: "bsb", ofType: "db")!
        db = try! Connection(path, readonly: true)
    }

    /// Returns the text for the specified range, or the given chapter for the original language or the BSB translation (default)
    public func text(book: Int, chapter: Int, verseRange: Range<Int>?, isOrig: Bool = false) -> String {
        let col = isOrig ? origText : bsbText
        
        // select the verses
        var table = interlinearTable.select(col).filter(bookId == book).filter(chapterId == chapter)
        if let range = verseRange {
            if range.startIndex == range.endIndex {
                table = table.filter(verseId == range.startIndex)
            } else {
                table = table.filter(verseId >= range.startIndex).filter(verseId < range.endIndex)
            }
        }
        
        let query = try? db.prepare(table)
        guard let query = query else {
            return ""
        }
        
        // build the full text value from all the rows/verses
        let fullText = NSMutableString()
        for row in query {
            let text = try! row.get(col)
            fullText.append(text + " ")
        }
        
        return (fullText as String).trimmingCharacters(in: .whitespaces)
    }
}
