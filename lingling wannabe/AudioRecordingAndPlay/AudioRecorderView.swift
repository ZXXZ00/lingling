//
//  AudioRecorderView.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 3/25/22.
//

import UIKit
import AVFoundation

class AudioRecorderView: UIView, AVAudioRecorderDelegate {
    
    let button = UIButton()
    let buttonConfig = UIImage.SymbolConfiguration(textStyle: .largeTitle, scale: .large)
    let recordIcon: UIImage?
    let stopIcon: UIImage?
    let label = UILabel()
    
    private var path: URL?
    var recorder: AVAudioRecorder?
    var delegate: AudioRecorderDelegate?
    var timer: Timer?
    
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
        button.widthAnchor.constraint(equalToConstant: recordIcon!.size.width + 10).isActive = true
        button.heightAnchor.constraint(equalToConstant: recordIcon!.size.height + 10).isActive = true
        
        label.font = UIFont(name: "AmericanTypewriter", size: 24)
        label.adjustsFontSizeToFitWidth = true
        label.textColor = .black
        label.textAlignment = .center
        label.text = "Record your progress"
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5).isActive = true
        label.heightAnchor.constraint(equalToConstant: 40).isActive = true
        NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 0.5, constant: 0).isActive = true
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
            recorder!.delegate = self
            print("start recording")
            delegate?.didBegin()
        } catch {
            // TODO: error handling
            print(error.localizedDescription)
        }
        label.text = "00:00"
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
            _ in
            guard let recorder = self.recorder else { return }
            if !recorder.isRecording { return }
            let minute = Int(recorder.currentTime) / 60
            let second = Int(recorder.currentTime) % 60
            self.label.text = String(format: "%02d:%02d", minute, second)
        }
        timer?.tolerance = 0.1
    }
    
    func stopRecording() {
        recorder?.stop()
        timer?.invalidate()
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            label.text = "Try again if not satisfied"
            delegate?.didFinish()
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        // TODO: error handling
    }
}
