//
//  DataManager.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 8/24/21.
//

import Foundation
import SQLite
import CoreImage
import CryptoKit

// This is the structure for each entry in the database
// the attributes is a json string used to store future attributes
// 0: unsynced, 1: synced
struct Record: Hashable {
    var username: String
    var time: Int64
    var duration: Int64
    var asset: String
    var synced: Bool
    var checksum: String
    var attributes: String?
    
    init(username: String, time: Int64, duration: Int64, asset: String, synced: Bool, checksum: String, attributes: String? = nil) {
        self.username = username
        self.time = time
        self.duration = duration
        self.asset = asset
        self.synced = synced
        self.checksum = checksum
        self.attributes = attributes
    }
    
    func toDict(withUsername: Bool) -> [String:Any] {
        var ret: [String:Any]
        if withUsername {
            ret = ["username": username, "start_time": time, "duration": duration, "checksum": checksum, "asset": asset]
        } else {
            ret = ["start_time": time, "duration": duration, "checksum": checksum, "asset": asset]
        }
        if let attr = attributes {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: attr.data(using: .utf8)!) as! [String:Any]
                ret.merge(jsonObject) {
                    (current, _) in current
                }
            } catch {
                print(error)
            }
        }
        return ret
    }
    
    static func == (lhs: Record, rhs: Record) -> Bool {
        return lhs.username == rhs.username && lhs.time == rhs.time
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(username)
        hasher.combine(time)
    }
}

enum DataStatus: Int {
    case invalid = 3
    case future = 2
    case conflict = 1
    case success = 0
    case tokenError = -1
    case insertError = -2
}

func computeCheckSum(start: Int, duration: Int) -> String {
    var bytes = [Int8] (repeating: 0, count: 16)
    let status = SecRandomCopyBytes(kSecRandomDefault, 16, &bytes)
    let frequency = 44100
    let lingling = 40
    
    if status != errSecSuccess {
        print(status)
        return ""
    }
    let random = Data(bytes: bytes, count: 16)
    let randomstr = random.compactMap { String(format: "%02x", $0) }.joined()
    let mod = 2147483647 // 2^31 - 1 prime
    var res = start % mod
    res = ((res * lingling) % mod + res) % mod // res * 41 where 41 is a prime
    res = ((res * frequency) % mod + res) % mod// res * 44101 where 44101
    res = (res * abs(duration)) % mod
    let resstr = String(res)
    let hashed = SHA256.hash(data: Data((resstr+randomstr).utf8))
    let ret = randomstr + hashed.compactMap { String(format: "%02x", $0) }.joined()
    return ret
}

func verifyCheckSum(start: Int, duration: Int, checksum: String) -> Bool {
    let frequency = 44100
    let lingling = 40
    if checksum.count != (32+16) * 2 { // sha256 produce 32 * 2 hexdigest, salt is 16 * 2 hexdigest
        return false
    }
    let mod = 2147483647
    var res = start % mod
    res = ((res * lingling) % mod + res) % mod // res * 41 where 41 is a prime
    res = ((res * frequency) % mod + res) % mod // res * 44101 where 44101
    res = (res * abs(duration)) % mod
    let resstr = String(res)
    let randomstr = String(checksum.prefix(16*2)) // first 16*2 is salt
    let hash = SHA256.hash(data: Data((resstr+randomstr).utf8))
    let hashstr = hash.compactMap { String(format: "%02x", $0) }.joined()
    return String(checksum.suffix(32*2)) == hashstr
}

final class DataManager {
    static let shared = DataManager()
    static let ConflictNotification = Notification.Name("DataConflict")
    
    let dbURL = URL(string: "https://linglingwannabe.com/record/record")!
    
    // the db is a connection to data.db which stores the record
    private var db: Connection!
    // the err is a connection to error.db which stores the error
    // there are two types of error: network and local, each is a table
    private var err: Connection!
    
    private var unsynced: Set<Record> = []
    // remove all unsynced if data has been previously resetted without removing all unsynced
    private var hasRestted = false
    
    private var totalMinutes = 0
    private let interval = 120
    private var canRecording = false
    
    private init() {
        do {
            let dir = getDocumentDirectory()
            db = try Connection(dir.appendingPathComponent("data.db").absoluteString)
            try db.run("CREATE TABLE IF NOT EXISTS records(username TEXT, time INTEGER, duration INTEGER NOT NULL, asset TEXT NOT NULL, synced INTEGER NOT NULL, checksum TEXT NOT NULL, attributes TEXT, PRIMARY KEY (username, time))")
            err = try Connection(dir.appendingPathComponent("error.db").absoluteString)
            try err.run("CREATE TABLE IF NOT EXISTS network(time REAL PRIMARY KEY, message TEXT)")
            try err.run("CREATE TABLE IF NOT EXISTS local(time REAL PRIMARY KEY, message TEXT)")
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
        if x.count != 7 {
            return nil
        }
        let tmp = x.map { cast($0) }
        if let username =  tmp[0] as? String,
           let time = tmp[1] as? Int64,
           let duration = tmp[2] as? Int64,
           let asset = tmp[3] as? String,
           let syncedInt = tmp[4] as? Int64,
           let checksum = tmp[5] as? String
        {
            let synced = syncedInt == 1
            return Record(username: username, time: time, duration: duration, asset: asset, synced: synced, checksum: checksum, attributes: tmp[6] as? String)
        }
        return nil
    }
    
    func getRecordingEligibility() -> Bool {
        if canRecording {
            canRecording = false
            return true
        } else {
            return false
        }
    }
    
    func insertErrorMessage(isNetwork: Bool, message: String) {
        let timestamp = Date().timeIntervalSince1970
        if isNetwork {
            do {
                try err.run("INSERT INTO network VALUES (?, ?)", timestamp, message)
            } catch {
                print("failed to insert into error database")
            }
        } else {
            do {
                try err.run("INSERT INTO local VALUES (?, ?)", timestamp, message)
            } catch {
                print("failed to insert into error database")
            }
        }
    }
    
    func updateSynced(username: String, time: Int) {
        do {
            try db.run("UPDATE records SET synced = 1 WHERE username=? AND time=?", username, time)
        } catch {
            print("failed to update sync")
        }
    }
    
    func uploadUnsynced(username: String, token: String?) {
        if unsynced.count == 0 { return }
        guard let token = token else { return }
        let json: [String:Any] = ["username": username, "records": unsynced.map({ $0.toDict(withUsername: false) })]
        postJSON(url: dbURL, json: json, token: token, success: { unprocessed, response in
            if response.statusCode == 200 {
                var unprocessedSet = Set<Int>()
                do {
                    let jsonobj = try JSONSerialization.jsonObject(with: unprocessed)
                    guard let arr = jsonobj as? [[String:Any]] else {
                        self.insertErrorMessage(isNetwork: true, message: "Failed to cast unprocessed as [[String:Any]]")
                        print("unprocessed fail")
                        return
                    }
                    for rec in arr {
                        if let st = rec["start_time"] as? Int {
                            unprocessedSet.insert(st)
                        }
                    }
                } catch {
                    self.insertErrorMessage(isNetwork: true, message: "Failed to read unprocessed \(error.localizedDescription)")
                    print("failed to cast unprocessed")
                    return
                }
                for r in self.unsynced {
                    if unprocessedSet.contains(Int(r.time)) { continue }
                    self.updateSynced(username: username, time: Int(r.time))
                    self.unsynced.remove(r)
                }
            } else if response.statusCode == 409 {
                NotificationCenter.default.post(name: DataManager.ConflictNotification, object: nil)
            } else {
                self.insertErrorMessage(isNetwork: true, message: "failed to upload unsynced part, status code \(response.statusCode)")
            }
        }, failure: { e in
            self.insertErrorMessage(isNetwork: false, message: e.localizedDescription )
        })
    }
    
    // Check if there could be any conflict with database
    func checkAndLoad(username: String, token: String?) -> DataStatus {
        let records = DataManager.shared.getRecord(username: username)
        if records.count == 0 { return .success }
        for i in 0..<records.count-1 {
            totalMinutes += Int(abs(records[i].duration) / 60)
            
            if records[i].time + abs(records[i].duration) > records[i+1].time {
                return DataStatus.conflict
            }
            
            let date = Date(timeIntervalSince1970: Double(records[i].time))
            addCache(username: username, date: date, asset: records[i].asset)
            
            if !records[i].synced {
                unsynced.insert(records[i])
            }
            if !verifyCheckSum(start: Int(records[i].time), duration: Int(records[i].duration), checksum: records[i].checksum) {
                return DataStatus.invalid
            }
        }
        if let last = records.last {
            totalMinutes += Int(abs(last.duration) / 60)
            
            let currentTime = Date().timeIntervalSince1970
            if Double(last.time + abs(last.duration)) > currentTime {
                return DataStatus.future
            }
            if Double(last.time + abs(last.duration)) > currentTime {
                return DataStatus.conflict
            }
            
            let date = Date(timeIntervalSince1970: Double(last.time))
            addCache(username: username, date: date, asset: last.asset)
            
            if !last.synced {
                unsynced.insert(last)
            }
            if !verifyCheckSum(start: Int(last.time), duration: Int(last.duration), checksum: last.checksum) {
                print("INVALID")
                return DataStatus.invalid
            }
        }
        uploadUnsynced(username: username, token: token)
        return DataStatus.success
    }

    // TODO: after finish a session, the record is inserted and it also triggers a sync that downloads the latest, which cause double add record
    func addRecord(username: String, time: Int, duration: Int, asset: String, attributes: String?, upload: Bool) -> DataStatus {
        let before = totalMinutes
        totalMinutes += abs(duration / 60)
        if (totalMinutes / interval - before / interval > 0) || (before == 0) {
            canRecording = true
        }
        
        let date = Date(timeIntervalSince1970: Double(time))
        
        if username == "guest" {
            addCache(username: username, date: date, asset: asset)
            return DataStatus.success
        }
        let checksum = computeCheckSum(start: time, duration: duration)
        do {
            if let attr = attributes {
                try db.run("INSERT INTO records (username, time, duration, asset, synced, checksum, attributes) VALUES (?, ?, ?, ?, ?, ?, ?)", username, time, duration, asset, 0, checksum, attr)
            } else {
                try db.run("INSERT INTO records (username, time, duration, asset, synced, checksum) VALUES (?, ?, ?, ?, ?, ?)", username, time, duration, asset, 0, checksum)
            }
        } catch {
            print(error)
            return DataStatus.insertError
        }
        addCache(username: username, date: date, asset: asset)
        let r = Record(username: username, time: Int64(time), duration: Int64(duration), asset: asset, synced: false, checksum: checksum, attributes: attributes)
        if !upload { return DataStatus.success }
        
        guard let token = CredentialManager.shared.getToken() else { return DataStatus.tokenError }
        let json = ["username": username, "records": [r.toDict(withUsername: false)]] as [String : Any]
        // TODO: implement semaphore to wait, maybe no need for semaphore
        postJSON(url: dbURL, json: json, token: token, success: { unprocessed, response in
            // TODO: handle non 200 situation and if there is unprocessed
            print("add record status: \(response.statusCode)")
            if response.statusCode == 200 {
                print("status 200, upload success")
                self.updateSynced(username: username, time: time)
                print("status 200 finished client handling")
            } else if response.statusCode == 409 {
                NotificationCenter.default.post(name: DataManager.ConflictNotification, object: nil)
            } else {
                self.unsynced.insert(r)
                self.insertErrorMessage(isNetwork: true, message: "Failed to insert (\(username), \(time), \(duration))\nstatusCode: \(response.statusCode)")
            }
        }, failure: { e in
            self.insertErrorMessage(isNetwork: false, message: e.localizedDescription)
        })
        return DataStatus.success
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
    
    func getLast(username: String) -> Record? {
        do {
            let stmt = try db.prepare("SELECT * FROM records WHERE username=? ORDER BY time DESC LIMIT 1", username)
            for row in stmt {
                return cast(row)
            }
        } catch {
            print(error)
        }
        return nil
    }

    func downloadRecord(username: String, start: Int?=nil, end: Int?=nil) {
        var url = URLComponents(url: dbURL, resolvingAgainstBaseURL: true)
        if let s = start, let e = end {
            url?.query = "username=\(username)&start_t=\(s)&end_t=\(e)"
        } else {
            url?.query = "username=\(username)"
        }
        guard let u = url?.url else { return }
        let now = Int(Date().timeIntervalSince1970)
        getJSON(url: u, success: { json in
            guard let arr = json as? [[String:Any]] else { return }
            for r in arr {
                if let st = r["start_time"] as? Int,
                   let duration = r["duration"] as? Int,
                   let asset = r["asset"] as? String {
                    if self.addRecord(username: username, time: st,
                                      duration: duration, asset: asset,
                                      attributes: nil, upload: false) == .success
                    {
                        self.updateSynced(username: username, time: st)
                    }
                } else {
                    print("failed to cast downloaded records", r)
                }
            }
            UserDefaults.standard.set(now, forKey: "LastSync_"+username)
        }, failure: { _ in }) // TODO: implement failure
    }
    
    func sync(username: String, token: String?) {
        if username == "guest" { return }
        // only sync after 15 minutes has passed since last sync
        let current = Int(Date().timeIntervalSince1970)
        let lastSync = UserDefaults.standard.integer(forKey: "LastSync_"+username)
        if (lastSync + 900 > current) { return }
        downloadRecord(username: username, start: lastSync, end: current)
        uploadUnsynced(username: username, token: token)
    }
    
    func clear() {
        if hasRestted {
            unsynced.removeAll()
        }
        do {
            try db.run("DELETE FROM records")
        } catch {
            print(error)
        }
        hasRestted = !hasRestted
    }
    
    func delete(username: String, time: Int) {
        do {
            try db.run("DELETE FROM records WHERE username=? AND time=?", username, time)
        } catch {
            print(error)
        }
    }
    
    func getErrors() -> String {
        var ret = ""
        do {
            let stmt = try err.prepare("SELECT * FROM local")
            for row in stmt {
                let tmp = row.map { cast($0) }
                if let time =  tmp[0] as? Double,
                   let errMsg = tmp[1] as? String {
                    ret += "\(time): \(errMsg)\n"
                }
            }
        } catch {
            print("failed to insert", error)
        }
        ret += "----\n"
        do {
            let stmt = try err.prepare("SELECT * FROM network")
            for row in stmt {
                let tmp = row.map { cast($0) }
                if let time = tmp[0] as? Double,
                   let errMsg = tmp[1] as? String {
                    ret += "\(time): \(errMsg)\n"
                }
            }
        } catch {
            print("failed to insert", error)
        }
        return ret
    }
}
