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

class AudioStreamAnalyzer {
    static let shared = AudioStreamAnalyzer()
    
    let classifier = TwoCategory()
    let model: MLModel

    let audioEngine = AVAudioEngine()
    let inputBus = AVAudioNodeBus(0)
    let inputFormat: AVAudioFormat
    let streamAnalyzer: SNAudioStreamAnalyzer
    let resultsObserver = ResultsObserver()
    let analysisQueue = DispatchQueue(label: "com.zxxz.AnalysisQueue")
    
    let outputFormatSettings = [
        AVFormatIDKey:kAudioFormatLinearPCM,
        AVLinearPCMBitDepthKey:32,
        AVLinearPCMIsFloatKey: true,
        //  AVLinearPCMIsBigEndianKey: false,
        AVSampleRateKey: Float64(44100.0),
        AVNumberOfChannelsKey: 1
        ] as [String : Any]
    
    private init() {
        model = classifier.model
        inputFormat = audioEngine.inputNode.inputFormat(forBus: inputBus)
        streamAnalyzer = SNAudioStreamAnalyzer(format: inputFormat)
    }

    func startAudioEngine() {
        do {
            try audioEngine.start()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func getDocumentDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    @objc func analyze() {
        startAudioEngine()
        print("start analyze")
        do {
            let request = try SNClassifySoundRequest(mlModel: model)
            try streamAnalyzer.add(request, withObserver: resultsObserver)
        } catch {
            print(error.localizedDescription)
            return
        }
        print(inputFormat.sampleRate)
        //let dft = vDSP.DFT(count: 8192, direction: .forward, transformType: .complexReal, ofType: Float.self)
        //var real = [Float](repeating: 0, count: 8192)
        //var imag = [Float](repeating: 0, count: 8192)
        //let tmp = UnsafeMutablePointer<Float>.allocate(capacity: 8192)
        //let emptyPtr: UnsafeBufferPointer<Float> = UnsafeBufferPointer(start: tmp, count: 8192)
        let url = getDocumentDirectory().appendingPathComponent("recording.wav")
        let audioFile = try? AVAudioFile(forWriting: url, settings: outputFormatSettings, commonFormat: AVAudioCommonFormat.pcmFormatFloat32, interleaved: true)
        audioEngine.inputNode.installTap(onBus: inputBus, bufferSize: 8192, format: inputFormat) {
            buffer, time in self.analysisQueue.async {
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
                self.streamAnalyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }
    }
    
    @objc func stop() {
        streamAnalyzer.completeAnalysis()
        audioEngine.inputNode.removeTap(onBus: inputBus)
        audioEngine.stop()
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
