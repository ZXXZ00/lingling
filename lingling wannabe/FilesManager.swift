//
//  FileManager.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 2/12/22.
//

import Foundation
import ffmpegkit
import UIKit
import SQLite

final class FilesManager {
    static let shared = FilesManager()
    let serialQueue = DispatchQueue(label: "com.zxxz.FileManager")
    let config: URLSessionConfiguration
    let networkSession: URLSession
    
    let url = URL(string: "https://5b3gjwu0uc.execute-api.us-east-1.amazonaws.com/upload")!
    
    private var db: Connection!

    private init() {
        config = URLSessionConfiguration.background(withIdentifier: "com.zxxz.FileManager")
        networkSession = URLSession(configuration: config)
        do {
            db = try Connection(getDocumentDirectory().appendingPathComponent("files.db").absoluteString)
            try db.run("CREATE TABLE IF NOT EXISTS files(username TEXT, time INTEGER, label TEXT, PRIMARY KEY (username, time))")
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
    
    func getLabels(username: String) -> [(String,String)] {
        var ret: [(String,String)] = []
        do {
            let stmt = try db.prepare("SELECT time, label FROM files WHERE username=?", username)
            for row in stmt {
                if let time = cast(row[0]) as? Int64,
                   let label = cast(row[1]) as? String {
                    ret.append((String(time), label))
                }
            }
        } catch {
            print(error)
        }
        return ret
    }
    
    func addLabel(username: String, time: Int, label: String) {
        do {
            try db.run("INSERT INTO files VALUES (?, ?, ?)", username, time, label)
        } catch {
            
        }
    }
    
    func upload(username: String, time: Int) {
        serialQueue.async {
            self.uploadHelper(username: username, time: time)
        }
    }
    
    private func uploadHelper(username: String, time: Int) {
        let fileURL = getDocumentDirectory().appendingPathComponent("recording.flac")
        do {
            let values = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            guard let size = values.fileSize else { return }
            if (size < 10*1024*1024 || size > 128*1024*1024) {
                return
            }
        } catch {
            return
        }
        postJSON(url: url, json: ["username": username, "filename": "\(time).flac"], token: nil, success: {
            data, res in
            if res.statusCode == 200 {
                guard let s3Link = String(data: data, encoding: .utf8),
                let s3URL = URL(string: s3Link) else { return }
                var request = URLRequest(url: s3URL)
                request.httpMethod = "PUT"
                request.allowsCellularAccess = false
                request.timeoutInterval = 3600
                request.setValue("audio/flac", forHTTPHeaderField: "Content-Type")
                let task = self.networkSession.uploadTask(with: request, fromFile: fileURL)
                task.resume()
            } else {
                DataManager.shared.insertErrorMessage(isNetwork: true, message: "request upload link, status code: \(res.statusCode)")
            }
        }, failure: { err in })
    }
    
    func convert2FLAC() {
        // TODO: need a better solution, the beginBackgroundTask only has 30s and may not be enough
        serialQueue.async {
            var identifier: UIBackgroundTaskIdentifier!
            identifier = UIApplication.shared.beginBackgroundTask(withName: "2FLAC", expirationHandler: {
                print(UIApplication.shared.backgroundTimeRemaining)
                print("opps! expired")
                DataManager.shared.insertErrorMessage(isNetwork: false, message: "not enough time to convert the format")
                UIApplication.shared.endBackgroundTask(identifier)
            })
            let src = getDocumentDirectory().appendingPathComponent("recording.wav").path
            let dst = getDocumentDirectory().appendingPathComponent("recording.flac").path
            let session = FFmpegKit.execute("-y -loglevel warning -i \(src) -c:a flac -sample_fmt s16 \(dst)")
            if let retcode = session?.getReturnCode(), retcode.isValueSuccess() {
                print("success")
                print(session?.getDuration())
                do {
                    try FileManager.default.removeItem(atPath: src)
                } catch {
                    print("failed to delete the src wav file \(error)")
                    DataManager.shared.insertErrorMessage(isNetwork: false, message: "failed to delete the src wav file \(error)")
                }
            } else {
                print("failed to convert flac \(session)")
                DataManager.shared.insertErrorMessage(isNetwork: false, message: "failed to convert to flac")
            }
            UIApplication.shared.endBackgroundTask(identifier)
        }
    }
}
