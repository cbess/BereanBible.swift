import Foundation
import SQLite

public struct BereanBibleManager {
    public private(set) var text = "Hello, World!"
    let path = Bundle.main.path(forResource: "bsb", ofType: "db")!
    let db: Connection
    
    public init() {
        db = try! Connection(path, readonly: true)
    }

}
