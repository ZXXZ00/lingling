//
//  FileManager.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 2/12/22.
//

import Foundation
import ffmpegkit
import UIKit

final class FilesManager {
    static let shared = FilesManager()
    let serialQueue = DispatchQueue(label: "com.zxxz.FileManager")
    let config: URLSessionConfiguration
    let networkSession: URLSession
    
    let url = URL(string: "https://5b3gjwu0uc.execute-api.us-east-1.amazonaws.com/upload")!

    private init() {
        config = URLSessionConfiguration.background(withIdentifier: "com.zxxz.FileManager")
        networkSession = URLSession(configuration: config)
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
                // TODO: error handling
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
            let session = FFmpegKit.execute("-y -i \(src) -c:a flac -sample_fmt s16 \(dst)")
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
