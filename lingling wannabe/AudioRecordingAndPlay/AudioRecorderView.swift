//
//  AudioRecorderView.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 3/25/22.
//

import UIKit
import AVFoundation

class AudioRecorderView: UIView {
    
    let button = UIButton()
    let buttonConfig = UIImage.SymbolConfiguration(textStyle: .largeTitle, scale: .large)
    let recordIcon: UIImage?
    let stopIcon: UIImage?
    
    private var path: URL?
    var recorder: AVAudioRecorder?
    var delegate: AVAudioRecorderDelegate?
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init(path: URL) {
        recordIcon = UIImage(systemName: "mic.fill", withConfiguration: buttonConfig)?.withTintColor(.black, renderingMode: .alwaysOriginal)
        stopIcon = UIImage(systemName: "stop.fill", withConfiguration: buttonConfig)?.withTintColor(.black, renderingMode: .alwaysOriginal)
        self.path = path
        super.init(frame: .zero)
        backgroundColor = .white
        
        button.setImage(recordIcon, for: .normal)
        button.addTarget(self, action: #selector(AudioRecorderView.toggleRecording), for: .touchUpInside)
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        button.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.3).isActive = true
        button.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3).isActive = true
    }
    
    @objc func toggleRecording() {
        if let _ = recorder {
            stopRecording()
            recorder = nil
            button.setImage(recordIcon, for: .normal)
        } else {
            button.setImage(stopIcon, for: .normal)
            startRecording()
        }
    }
    
    func startRecording() {
        guard let path = path else { return }
        
        let settings: [String:Any] = [
            AVFormatIDKey: Int(kAudioFormatFLAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
        ]
        do {
            recorder = try AVAudioRecorder(url: path, settings: settings)
            recorder!.prepareToRecord()
            recorder!.record()
            recorder!.delegate = delegate
            print("start recording")
        } catch {
            // TODO: error handling
            print(error.localizedDescription)
        }
    }
    
    func stopRecording() {
        recorder?.stop()
    }
    
}
