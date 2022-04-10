//
//  Metronome.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/16/21.
//

import Foundation
import AVFoundation

public class Metronome {
    
    let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    let buffer : AVAudioPCMBuffer
    let file : AVAudioFile
    var length : UInt32
    var bpm = 60 {
        didSet {
            let isPlaying = player.isPlaying
            player.stop()
            length = UInt32(sr * 60.0/(Double(bpm)))
            buffer.frameLength = length
            if (isPlaying) {
                do {
                    try start()
                } catch {
                    DataManager.shared.insertErrorMessage(isNetwork: false, message: "couldn't start motronome: \(error)")
                    print(error)
                }
            }
        }
    }
    public var isPlaying : Bool {
        get {
            return player.isPlaying
        }
    }
    let sr : Double = 48000 // the sample rate for tick.wav
    
    public init?() { // start off as 60 bpm
        guard let url = Bundle.main.url(forResource: "tick", withExtension: "wav") else { return nil }
        file = try! AVAudioFile(forReading: url)
        length = UInt32(sr * 60.0/(Double(bpm)))
        if let buff = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: UInt32(sr*2)) {
            // times 2 because the slowest it will be is 40 bpm
            // and the standard is 60 bpm so it will have sufficent capcaity
            buffer = buff
        } else {
            return nil
        }
        do {
            try file.read(into: buffer)
            buffer.frameLength = length
        } catch {
            print(error.localizedDescription)
            return nil
        }
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: buffer.format)
        engine.prepare()
        do {
            try engine.start()
        } catch {
            print("Failed to start metronome audio engine: \(error.localizedDescription)")
            return nil
        }
    }

    public func destroy() {
        player.stop()
        engine.stop()
    }
    
    public func startEngine() throws {
        try engine.start()
    }
    
    @objc public func start() throws {
        if (!engine.isRunning) {
            try engine.start()
        }
        player.prepare(withFrameCount: length)
        player.play()
        player.scheduleBuffer(buffer, at: nil, options: .loops)
    }
    
    @objc public func pause() {
        if !engine.isRunning {
            return
        }
        player.stop()
        engine.pause()
    }
}
