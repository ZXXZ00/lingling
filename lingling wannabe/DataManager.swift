//
//  DataManager.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 8/24/21.
//

import Foundation
import SQLite


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
    
    private var db: Connection!
    
    private init() {
        do {
            let path = getDocumentDirectory().appendingPathComponent("data.db")
            db = try Connection(path.absoluteString)
            try db.run("CREATE TABLE IF NOT EXISTS records(username TEXT, time INTEGER, duration INTEGER NOT NULL, asset TEXT NOT NULL, attributes TEXT, PRIMARY KEY (username, time))")
        } catch {
            print(error)
        }
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
    
    // Check if there could be any conflict with database
    // return 0: OK
    // return 1: Overlapping session
    // return 2: Most recent record is in the future comparing to system time
    func checkAndLoad(username: String, time: Double) -> Int {
        let records = DataManager.shared.getRecord(username: username)
        if records.count == 0 { return 0 }
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        for i in 0..<records.count-1 {
            if records[i].time + abs(records[i].duration) > records[i+1].time {
                print("CONFLICT") // TODO: add warning to user
                return 1
            }
            
            let date = Date(timeIntervalSince1970: Double(records[i].time))
            let key = formatter.string(from: date)
            //if CalendarData.cache[key] != nil {
            //    CalendarData.cache[key]!.append(records[i].asset)
            //} else {
            //    CalendarData.cache[key] = [records[i].asset]
            //}
            if CalendarData.cache.keys.contains(username) {
                if CalendarData.cache[username]!.keys.contains(key) {
                    CalendarData.cache[username]![key]!.append(records[i].asset)
                } else {
                    CalendarData.cache[username]![key] = [records[i].asset]
                }
            } else {
                CalendarData.cache[username] = [key:[records[i].asset]]
            }
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
            let key = formatter.string(from: date)
            //if CalendarData.cache[key] != nil {
            //    CalendarData.cache[key]!.append(last.asset)
            //} else {
            //    CalendarData.cache[key] = [last.asset]
            //}
            if CalendarData.cache.keys.contains(username) {
                if CalendarData.cache[username]!.keys.contains(key) {
                    CalendarData.cache[username]![key]!.append(last.asset)
                } else {
                    CalendarData.cache[username]![key] = [last.asset]
                }
            } else {
                CalendarData.cache[username] = [key:[last.asset]]
            }
        }
        return 0
    }
    
    func addRecord(username: String, time: Int, duration: Int, assset: String) {
        do {
            try db.run("INSERT INTO records (username, time, duration, asset) VALUES (?, ?, ?, ?)", username, time, duration, assset)
        } catch {
            print(error)
        }
        let json = ["username": username, "records": ["start_time": time, "duration": duration, "asset": assset]] as [String : Any]
        if username == "guest" { return }
        postJSON(url: dbURL, json: json, success: {_, _ in }, failure: {error in print(error)})
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
        let username = "lingling"
        let batch = getRecord(username: username, start: 0, end: 2147483646)
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
