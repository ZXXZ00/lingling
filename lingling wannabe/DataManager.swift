//
//  DataManager.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 8/24/21.
//

import Foundation
import SQLite
import CoreImage


// This is the structure for each entry in the database
// the attributes is a json string used to store future attributes
struct Record {
    let username: String
    let time: Int64
    let duration: Int64
    let asset: String
    let attributes: String?
    
    init(username: String, time: Int64, duration: Int64, asset: String, attributes: String? = nil) {
        self.username = username
        self.time = time
        self.duration = duration
        self.asset = asset
        self.attributes = attributes
    }
    
    func toDict(withUsername: Bool = true) -> [String:Any] {
        var ret: [String:Any]
        if withUsername {
            ret = ["username": username, "start_time": time, "duration": duration, "asset": asset]
        } else {
            ret = ["start_time": time, "duration": duration, "asset": asset]
        }
        if let attr = attributes {
            do {
                try ret.merge(JSONSerialization.jsonObject(with: attr.data(using: .utf8)!) as! [String:Any]) {
                    (current, _) in current
                }
            } catch {
                print(error)
            }
        }
        return ret
    }
}

class DataManager {
    static let shared = DataManager()
    
    let dbURL = URL(string: "https://j7by90n61a.execute-api.us-east-1.amazonaws.com/record")!
    
    // the db is a connection to data.db which stores the record
    private var db: Connection!
    // the err is a connection to error.db which stores the error
    // there are two types of error: network and local, each is a table
    private var err: Connection!
    
    var initialized = false
    
    private init() {
        do {
            let dir = getDocumentDirectory()
            db = try Connection(dir.appendingPathComponent("data.db").absoluteString)
            try db.run("CREATE TABLE IF NOT EXISTS records(username TEXT, time INTEGER, duration INTEGER NOT NULL, asset TEXT NOT NULL, attributes TEXT, PRIMARY KEY (username, time))")
            err = try Connection(dir.appendingPathComponent("error.db").absoluteString)
            try err.run("CREATE TABLE IF NOT EXISTS network(time REAL PRIMARY KEY, message TEXT)")
            try err.run("CREATE TABLE IF NOT EXISTS local(time REAL PRIMARY KEY, message TEXT)")
            initialized = true
        } catch {
            print(error)
        }
    }
    
    func isInitialized() -> Bool {
        return initialized
    }
    
    private func cast(_ x: Binding?) -> Any? {
        switch x {
        case let integer as Int64:
            return integer
        case let double as Double:
            return double
        case let string as String:
            return string
        default:
            return nil
        }
    }
    
    private func cast(_ x: [Binding?]) -> Record? {
        if x.count != 5 {
            return nil
        }
        let tmp = x.map { cast($0) }
        if let username =  tmp[0] as? String,
           let time = tmp[1] as? Int64,
           let duration = tmp[2] as? Int64,
           let asset = tmp[3] as? String
        {
            return Record(username: username, time: time, duration: duration, asset: asset, attributes: tmp[4] as? String)
        }
        return nil
    }
    
    func insertErrorMessage(isNetwork: Bool, message: String) {
        let timestamp = Date().timeIntervalSince1970
        if isNetwork {
            do {
                try err.run("INSERT INTO network VALUES (?, ?)", timestamp, message)
            } catch {
                print("failed to insert into error database")
            }
        }
    }
    
    // Check if there could be any conflict with database
    // return 0: OK
    // return 1: Overlapping session
    // return 2: Most recent record is in the future comparing to system time
    func checkAndLoad(username: String, time: Double) -> Int {
        let records = DataManager.shared.getRecord(username: username)
        if records.count == 0 { return 0 }
        for i in 0..<records.count-1 {
            if records[i].time + abs(records[i].duration) > records[i+1].time {
                print("CONFLICT")
                return 1
            }
            
            let date = Date(timeIntervalSince1970: Double(records[i].time))
            addCache(username: username, date: date, asset: records[i].asset)
        }
        if let last = records.last {
            if Double(last.time + abs(last.duration)) > Date().timeIntervalSince1970 {
                print("FUTURE") // TODO: add warning
                return 2
            }
            if Double(last.time + abs(last.duration)) > time {
                print("CONFLICT")
                return 1
            }
            
            let date = Date(timeIntervalSince1970: Double(last.time))
            addCache(username: username, date: date, asset: last.asset)
        }
        return 0
    }
    
    func addRecord(username: String, time: Int, duration: Int, asset: String, attributes: String) {
        do {
            try db.run("INSERT INTO records (username, time, duration, asset, attributes) VALUES (?, ?, ?, ?, ?)", username, time, duration, asset, attributes)
        } catch {
            print(error)
        }
        let date = Date(timeIntervalSince1970: Double(time))
        addCache(username: username, date: date, asset: asset)
        if username == "guest" { return }
        let json = ["username": username, "records": [["start_time": time, "duration": duration, "asset": asset, "attributes": attributes]]] as [String : Any]
        postJSON(url: dbURL, json: json, success: { data, response in
            if response.statusCode == 200 {
                UserDefaults.standard.set(time+duration, forKey: "last_synced")
            } else {
                self.insertErrorMessage(isNetwork: true, message: "Failed to insert (\(username), \(time), \(duration))\nstatusCode: \(response.statusCode)")
            }
        }, failure: { e in
            self.insertErrorMessage(isNetwork: false, message: e.localizedDescription)
        })
    }
    
    func getRecord(username: String) -> [Record]{
        var ret: [Record] = []
        do {
            let stmt = try db.prepare("SELECT * FROM records WHERE username=?", username)
            for row in stmt {
                if let ent = cast(row) {
                    ret.append(ent)
                } else {
                    print("failed to retrieve from database", row)
                }
            }
        } catch {
            print(error)
        }
        return ret
    }
    
    func getRecord(username: String, start: Int, end: Int) -> [Record] {
        var ret: [Record] = []
        do {
            let stmt = try db.prepare("SELECT * FROM records WHERE username=? AND time BETWEEN ? AND ?", username, start, end)
            for row in stmt {
                if let ent = cast(row) {
                    ret.append(ent)
                } else {
                    print("failed to retrieve from database", row)
                }
            }
        } catch {
            print(error)
        }
        return ret
    }
    
    func clear() {
        do {
            try db.run("DELETE FROM records")
        } catch {
            print(error)
        }
    }
    
    func sync() {
        guard let username = UserDefaults.standard.string(forKey: "username") else { return }
        if username == "guest" { return }
        let last = UserDefaults.standard.integer(forKey: "last_synced")
        let batch = getRecord(username: username, start: last+1, end: 2147483646)
        if batch.count == 0 {
            return
        }
        var json: [String:Any] = ["username": username, "records": batch.map({ $0.toDict(withUsername: false) })]
        postJSON(url: dbURL, json: json, success: {_,_ in }, failure: {_ in})
    }
    
    func test() {
        do {
            //try db.run("INSERT INTO records (username, time, duration, asset, attributes) VALUES (\"lingling\", 1630283091, 1, \"test\", '{\"instrument\": \"piano\"}')")
            try db.run("DELETE FROM records WHERE asset=?", "test")
        } catch {
            print("failed to insert", error)
        }
    }
}
