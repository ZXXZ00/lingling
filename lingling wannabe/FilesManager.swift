//
//  FileManager.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 2/12/22.
//

import Foundation
import ffmpegkit

class FilesManager {
    static let shared = FilesManager()
    let serialQueue = DispatchQueue(label: "com.zxxz.FileSerial")
    
    private init() {
        
    }
    
    func convert2FLAC() {
        serialQueue.async {
            let src = getDocumentDirectory().appendingPathComponent("recording.wav").path
            let dst = getDocumentDirectory().appendingPathComponent("recording.flac").path
            let session = FFmpegKit.execute("-y -i \(src) -c:a flac -sample_fmt s16 \(dst)")
            if let retcode = session?.getReturnCode(), retcode.isValueSuccess() {
                print("success")
                // TODO: upload to aws
            } else {
                print("failed to convert flac \(session)")
            }
        }
    }
    
}
