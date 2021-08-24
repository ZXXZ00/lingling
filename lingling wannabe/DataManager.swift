//
//  DataManager.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 8/24/21.
//

import Foundation
import SQLite

class DataManager {
    static let shared = DataManager()
    
    private var db: Connection!
    
    init() {
        do {
            let path = getDocumentDirectory().appendingPathComponent("data.db")
            db = try Connection(path.absoluteString)
            try db.run("CREATE TABLE IF NOT EXISTS records(username TEXT, time INTEGER, duration INTEGER NOT NULL, asset TEXT NOT NULL, attributes TEXT, PRIMARY KEY (username, time))")
        } catch {
            print(error)
        }
    }
    
    func test() {
        do {
            //try db.run("INSERT INTO records (username, time, duration, asset) VALUES (\"lingling\", 20, 60, \"test\")")
            let stmt = try db.prepare("SELECT * FROM records")
            for row in stmt {
                print(row)
            }
        } catch {
            print("failed to insert", error)
        }
    }
}
