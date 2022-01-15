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
    
    let outputFormatSettings = [
        AVFormatIDKey:kAudioFormatLinearPCM,
        AVLinearPCMBitDepthKey:32,
        AVLinearPCMIsFloatKey: true,
        //  AVLinearPCMIsBigEndianKey: false,
        AVSampleRateKey: Float64(44100.0),
        AVNumberOfChannelsKey: 1
        ] as [String : Any]
    
    let compressedFormatSettings = [
        AVFormatIDKey: kAudioFormatFLAC,
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
        AVLinearPCMBitDepthKey: 16
    ] as [String: Any]
    
    let convertFormat: AVAudioFormat
    let converter: AVAudioConverter?
    var outRef: ExtAudioFileRef?
    
    init() {
        //model = classifier.model
        inputFormat = audioEngine.inputNode.inputFormat(forBus: inputBus)
        streamAnalyzer = SNAudioStreamAnalyzer(format: inputFormat)
        
        let conf = MLModelConfiguration()
        conf.computeUnits = .cpuOnly
        do {
            let tmp = try TwoCategory(configuration: conf)
            model = tmp.model
        } catch {
            print("failed to initilize ml model")
        }
        
        // TODO: check convertFormat is not nil
        convertFormat = AVAudioFormat(settings: compressedFormatSettings)!
        converter = AVAudioConverter(from: inputFormat, to: convertFormat)
        //let compURL = getDocumentDirectory().appendingPathComponent("compressed.flac")
        //ExtAudioFileCreateWithURL(compURL as CFURL, kAudioFileCAFType, convertFormat.streamDescription, convertFormat.channelLayout?.layout, AudioFileFlags.eraseFile.rawValue, &outRef)
        //ExtAudioFileSetProperty(outRef!, kExtAudioFileProperty_ClientDataFormat, UInt32(MemoryLayout.size(ofValue: inputFormat.streamDescription.pointee)), inputFormat.streamDescription)
        //print(outRef)
    }

    func startAudioEngine() {
        do {
            try audioEngine.start()
        } catch {
            print(error.localizedDescription)
        }
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
    
    @objc func analyze() {
        print("start analyze")
        do {
            let request = try SNClassifySoundRequest(mlModel: model)
            try streamAnalyzer.add(request, withObserver: resultsObserver)
        } catch {
            print(error.localizedDescription)
            return
        }
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
        
        
        audioEngine.inputNode.installTap(onBus: inputBus, bufferSize: UInt32(buffSize), format: inputFormat) {
            buffer, time in self.analysisQueue.async {
                //self.ft(buffer.floatChannelData![0])
                //assert(buffer.frameLength == UInt32(self.buffSize))
                //let floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: 8192))
                //let bufferPtr = UnsafeBufferPointer(start: buffer.floatChannelData![0], count: 8192)
                //dft?.transform(inputReal: bufferPtr, inputImaginary: emptyPtr, outputReal: &real, outputImaginary: &imag)
                //print(real.reduce(0, +), real.indices.max(by: {real[$0] < real[$1]} ))
                //print(imag.reduce(0, +), imag.indices.max(by: {imag[$0] < imag[$1]} ))
                
                // input block is called when the converter needs input
                //let inputBlock : AVAudioConverterInputBlock = { (inNumPackets, outStatus) -> AVAudioBuffer? in
                //    outStatus.pointee = AVAudioConverterInputStatus.haveData;
                //    return buffer; // fill and return input buffer
                //}
                //let compressedBuffer = AVAudioCompressedBuffer(format: self.convertFormat, packetCapacity: 8, maximumPacketSize: self.converter!.maximumOutputPacketSize)
                //var outError: NSError? = nil
                //self.converter?.convert(to: compressedBuffer, error: &outError, withInputFrom: inputBlock)
                //if let oe = outError {
                //    print("error: \(oe)")
                //} else {
                    //let mBuff = compressedBuffer.audioBufferList.pointee.mBuffers
                    //if let mdata = mBuff.mData {
                    //    let len = Int(mBuff.mDataByteSize)
                    //    let data = Data(bytes: mdata, count: len)
                    //    print(len, data)
                    //    do {
                    //        try data.write(to: compURL)
                    //    } catch {
                    //        print(error.localizedDescription)
                    //    }
                    //}

                    //ExtAudioFileWrite(self.outRef!, 16, compressedBuffer.audioBufferList)
                //}
                do {
                    try audioFile?.write(from: buffer)
                } catch {
                    print(error.localizedDescription)
                }
                self.streamAnalyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }
        startAudioEngine()
    }
    
    @objc func stop() {
        streamAnalyzer.completeAnalysis()
        audioEngine.inputNode.removeTap(onBus: inputBus)
        audioEngine.stop()
        //ExtAudioFileDispose(outRef!)
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
