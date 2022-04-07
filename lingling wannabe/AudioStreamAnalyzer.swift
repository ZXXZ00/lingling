//
//  AudioStreamAnalyzer.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 1/22/21.
//  Copyright © 2021 Adam Zhao. All rights reserved.
//

import Foundation
import AVFoundation
import SoundAnalysis
import Accelerate
import AudioToolbox
import CoreAudio

class AudioStreamAnalyzer {
    
    var model: MLModel!
    
    let BUFFSIZE: UInt32 = 8192
    
    let audioEngine = AVAudioEngine()
    let inputBus = AVAudioNodeBus(0)
    let inputFormat: AVAudioFormat
    let streamAnalyzer: SNAudioStreamAnalyzer
    let resultsObserver = ResultsObserver()
    let analysisQueue = DispatchQueue(label: "com.zxxz.AnalysisQueue")
    
    private var lastCheckTime = 0.0
    private var timeElapsed = 0.0
    var isWritingToFile = true
    
    let outputFormatSettings: [String : Any]
    
    let minimumAvaiableSpace: Int64 = 1024 * 1024 * 1024 // 1024 MB
    
    init() {
        inputFormat = audioEngine.inputNode.inputFormat(forBus: inputBus)
        streamAnalyzer = SNAudioStreamAnalyzer(format: inputFormat)
        
        outputFormatSettings = [
            AVFormatIDKey:kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey:32,
            AVLinearPCMIsFloatKey: true,
            //  AVLinearPCMIsBigEndianKey: false,
            AVSampleRateKey: inputFormat.sampleRate,
            AVNumberOfChannelsKey: 1
        ]
        
        let conf = MLModelConfiguration()
        conf.computeUnits = .cpuOnly
        do {
            let tmp = try TwoCategory(configuration: conf)
            model = tmp.model
        } catch {
            print("failed to initilize ml model")
        }
    }

    func startAudioEngine() throws {
        try audioEngine.start()
    }

    @objc func analyze() throws {
        timeElapsed = 0.0
        let request = try SNClassifySoundRequest(mlModel: model)
        try streamAnalyzer.add(request, withObserver: resultsObserver)
        
        print(inputFormat.streamDescription.pointee.mBitsPerChannel)
        print(inputFormat.streamDescription.pointee.mFormatID)
        print(inputFormat.streamDescription.pointee.mChannelsPerFrame)
        print(inputFormat.streamDescription.pointee.mBytesPerFrame)
        print(inputFormat.streamDescription.pointee.mBytesPerPacket)
        print(inputFormat.streamDescription.pointee.mSampleRate)
        print(inputFormat.streamDescription.pointee.mFormatFlags)
        print(inputFormat.streamDescription.pointee.mFramesPerPacket)
        
        let url = getDocumentDirectory().appendingPathComponent("recording.wav")
        let audioFile: AVAudioFile?
        if let size = getAvailableSpace(at: getDocumentDirectory()) {
            if size < minimumAvaiableSpace { isWritingToFile = false } // smaller than 5 GB
        } else {
            isWritingToFile = false
        }
        if isWritingToFile {
            audioFile = try? AVAudioFile(forWriting: url, settings: outputFormatSettings, commonFormat: AVAudioCommonFormat.pcmFormatFloat32, interleaved: true)
        } else {
            audioFile = nil
        }
        
        var startTime = -1.0
        audioEngine.inputNode.installTap(onBus: inputBus, bufferSize: BUFFSIZE, format: inputFormat) {
            buffer, time in self.analysisQueue.async {
                do {
                    try audioFile?.write(from: buffer)
                } catch {
                    print(error.localizedDescription)
                }
                if startTime < 0 {
                    startTime = Double(time.sampleTime) / time.sampleRate
                } else {
                    self.timeElapsed = Double(time.sampleTime) / time.sampleRate - startTime
                }
                
                self.streamAnalyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }
        try startAudioEngine()
    }
    
    func timeDelta() -> Double {
        let copy = lastCheckTime
        lastCheckTime = timeElapsed
        return lastCheckTime - copy
    }
    
    @objc func stop() {
        streamAnalyzer.completeAnalysis()
        audioEngine.inputNode.removeTap(onBus: inputBus)
        audioEngine.stop()
        if isWritingToFile {
            FilesManager.shared.convert2FLAC()
        }
    }
    
    func pause() {
        audioEngine.pause()
    }
}

class ResultsObserver : NSObject, SNResultsObserving {
    
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult else { return }
            //let classification = result.classifications.first else { return }
        //let formattedTime = String(format: "%.2f", result.timeRange.start.seconds)
        //print("time: \(formattedTime)")
        //print("\(result.timeRange.start.seconds), \(result.timeRange.end.seconds)")
        //let confidence = classification.confidence * 100.0
        //let percent = String(format: "%.2f%%", confidence)
        //print("\(classification.identifier): \(percent) \n")
        
        //time.append(result.timeRange.start.seconds)
        //results.append(result.classifications)
        ResultDelegate.shared.append(start: result.timeRange.start.seconds, end: result.timeRange.end.seconds,
                                     result.classifications)
    }
    
    func request(_ request: SNRequest, didFailWithError error: Error) {
        print(error.localizedDescription)
        DataManager.shared.insertErrorMessage(isNetwork: false, message: "SNRequest Fails: \(error)")
    }
    
    func requestDidComplete(_ request: SNRequest) {
    }
}
