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
    
    // This idea might be ditched
    // Note: have to use DFT with .complexComplex and use first half
    // for consistency with Numpy, Scipy, PyTorch
    
    // perform a DFT on 1 minute audio input for every minute
    // one seconds audio data has buffer length 8192
    let buffSize = 8192
    let dft = vDSP.DFT(count: 512, direction: .forward, transformType: .complexComplex, ofType: Float.self)
    var realIn = [Float](repeating: 0, count: 4096*60)
    var imagIn = [Float](repeating: 0, count: 4096*60)
    var realOut = [Float](repeating: 0, count: 4096*60)
    var imagOut = [Float](repeating: 0, count: 4096*60)
    
    let audioEngine = AVAudioEngine()
    let inputBus = AVAudioNodeBus(0)
    let inputFormat: AVAudioFormat
    let streamAnalyzer: SNAudioStreamAnalyzer
    let resultsObserver = ResultsObserver()
    let analysisQueue = DispatchQueue(label: "com.zxxz.AnalysisQueue")
    
    var timeElapsed = 0.0
    
    let outputFormatSettings: [String : Any]
    
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
        try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        try audioEngine.start()
    }
    
    func joint(_ buffer: UnsafeMutablePointer<Float>, tick: Int) {
        for i in stride(from: 0, to: buffSize, by: 2) {
            realIn[tick*buffSize + i/2] = buffer[i]
            imagIn[tick*buffSize + i/2] = buffer[i+1]
        }
    }
    
    func ft(_ buffer : UnsafeMutablePointer<Float>) { // Fourier Transform
        for i in stride(from: 0, to: buffSize, by: 2) {
            realIn[i/2] = buffer[i]
            imagIn[i/2] = buffer[i+1]
        }
        dft?.transform(inputReal: realIn, inputImaginary: imagIn, outputReal: &realOut, outputImaginary: &imagOut)
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
        //let dft = vDSP.DFT(count: 8192, direction: .forward, transformType: .complexReal, ofType: Float.self)
        //var real = [Float](repeating: 0, count: 8192)
        //var imag = [Float](repeating: 0, count: 8192)
        //let tmp = UnsafeMutablePointer<Float>.allocate(capacity: 8192)
        //let emptyPtr: UnsafeBufferPointer<Float> = UnsafeBufferPointer(start: tmp, count: 8192)
        
        let url = getDocumentDirectory().appendingPathComponent("recording.wav")
        let audioFile = try? AVAudioFile(forWriting: url, settings: outputFormatSettings, commonFormat: AVAudioCommonFormat.pcmFormatFloat32, interleaved: true)
        
        var startTime = -1.0
        audioEngine.inputNode.installTap(onBus: inputBus, bufferSize: UInt32(buffSize), format: inputFormat) {
            buffer, time in self.analysisQueue.async {
                //self.ft(buffer.floatChannelData![0])
                //assert(buffer.frameLength == UInt32(self.buffSize))
                //let floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: 8192))
                //let bufferPtr = UnsafeBufferPointer(start: buffer.floatChannelData![0], count: 8192)
                //dft?.transform(inputReal: bufferPtr, inputImaginary: emptyPtr, outputReal: &real, outputImaginary: &imag)
                //print(real.reduce(0, +), real.indices.max(by: {real[$0] < real[$1]} ))
                //print(imag.reduce(0, +), imag.indices.max(by: {imag[$0] < imag[$1]} ))
                
                do {
                    try audioFile?.write(from: buffer)
                } catch {
                    print(error.localizedDescription)
                }
                if startTime < 0 {
                    startTime = AVAudioTime.seconds(forHostTime: time.hostTime)
                } else {
                    self.timeElapsed = AVAudioTime.seconds(forHostTime: time.hostTime) - startTime
                }
                
                self.streamAnalyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }
        try startAudioEngine()
    }
    
    @objc func stop() {
        streamAnalyzer.completeAnalysis()
        audioEngine.inputNode.removeTap(onBus: inputBus)
        audioEngine.stop()
        FilesManager.shared.convert2FLAC()
    }
    
    func pause() {
        audioEngine.pause()
    }
}

class ResultsObserver : NSObject, SNResultsObserving {
    
    //let delegate = ResultDelegate()
    
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
    }
    
    func requestDidComplete(_ request: SNRequest) {
        //time.removeAll()
        //results.removeAll()
        print("completed")
    }
}
