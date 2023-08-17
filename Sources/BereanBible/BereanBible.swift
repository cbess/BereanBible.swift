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
    public private(set) var text = "Hello, World!"
    let path = Bundle.main.path(forResource: "bsb", ofType: "db")!
    let db: Connection
    
    public init() {
        db = try! Connection(path, readonly: true)
    }

    public func text(book: Int, chapter: Int, verse: Int?) -> String {
        var table = interlinearTable.select(origText).filter(bookId == book).filter(chapterId == chapter)
        if let verse = verse {
            table = table.filter(verseId == verse)
        }
        
        let query = try? db.prepare(table)
        guard let query = query else {
            return ""
        }
        
        var fullText = NSMutableString()
        for row in query {
            fullText.append(try! row.get(origText))
        }
        
        return fullText as String
    }
}
