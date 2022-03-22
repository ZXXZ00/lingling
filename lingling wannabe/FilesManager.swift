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
    
    private init() {
        config = URLSessionConfiguration.background(withIdentifier: "com.zxxz.FileManager")
        networkSession = URLSession(configuration: config)
    }
    
    func convert2FLAC() {
        // TODO: need a better solution, the beginBackgroundTask only has 30s and may not be enough
        serialQueue.async {
            let identifier = UIApplication.shared.beginBackgroundTask(withName: "2FLAC", expirationHandler: {
                print(UIApplication.shared.backgroundTimeRemaining)
                print("opps! expired")
                DataManager.shared.insertErrorMessage(isNetwork: false, message: "not enough time to convert the format")
            })
            let src = getDocumentDirectory().appendingPathComponent("recording.wav").path
            let dst = getDocumentDirectory().appendingPathComponent("recording.flac").path
            let session = FFmpegKit.execute("-y -i \(src) -c:a flac -sample_fmt s16 \(dst)")
            if let retcode = session?.getReturnCode(), retcode.isValueSuccess() {
                print("success")
                print(session?.getDuration())
                // TODO: upload to aws
            } else {
                print("failed to convert flac \(session)")
            }
            UIApplication.shared.endBackgroundTask(identifier)
        }
    }
    
}
