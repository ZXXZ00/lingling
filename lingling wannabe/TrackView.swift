//
//  TrackView.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/3/23.
//

import UIKit
import AVFoundation

let SAMPLE_RATE = 44100
let WINDOW_DURATION = 4

class TrackView: UIView {
    
    private let player: AVPlayer
    let audioView = FDWaveformView()
    
    var zoomRatio: CGFloat = 1 {
        didSet {
            offset = Int(Double(WINDOW_DURATION) / 2.0 * Double(SAMPLE_RATE) * zoomRatio)
        }
    }
    var offset = WINDOW_DURATION / 2 * SAMPLE_RATE
    let PREFERED_SCALE: Int32 = 1000
    let MIN_WINDOW_DURATION = 1.0 / 30.0
    
    var test_val = 0
    var test_diff = 0
    
    // check if player was playing before pan gesture
    var wasPlaying = false
    var isPaning = false
    var isPinching  = false
        
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init(player: AVPlayer) {
        self.player = player
        super.init(frame: .zero)
        player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 60), queue: .main) {[weak self] _ in
            self?.setTimeline()
        }
    }
    
    func loadAsset(asset: AVAsset) {
        audioView.loadAsset(asset: asset)
    }
    
    func setTimeline() {
        guard !isPaning, let duration = player.currentItem?.duration else { return }
        let percentage = player.currentTime().seconds / duration.seconds
        let start = Int(Double(audioView.totalSamples) * percentage) - offset
        audioView.zoomSamples = start ..< start + Int(Double(WINDOW_DURATION) * zoomRatio * Double(SAMPLE_RATE))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.addLine(start: CGPoint(x: frame.width/2, y: 0), end: CGPoint(x: frame.width/2, y: frame.height), width: 2, color: .systemYellow)
        
        audioView.doesAllowScrubbing = false
        audioView.doesAllowStretch = false
        audioView.doesAllowScroll = false
        audioView.waveformType = .linear
        audioView.wavesColor = .black
        audioView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        addSubview(audioView)
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        audioView.addGestureRecognizer(panRecognizer)
        let pinRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture))
        audioView.addGestureRecognizer(pinRecognizer)
        
//        wav = WaveFormLayer(table: [Float], isMirrored: true)
//        wav.updateLayer(with: CGSize(width: frame.width, height: 80))
    }
    
    @objc func handlePinchGesture(_ recognizer: UIPinchGestureRecognizer) {
        guard recognizer.scale != 1, let duration = player.currentItem?.duration else { return }
        
        if recognizer.state == .began {
            isPinching = true
        }
        
        let windowSize = Double(WINDOW_DURATION) * zoomRatio / recognizer.scale
        if windowSize > MIN_WINDOW_DURATION && windowSize < duration.seconds * 2 {
            zoomRatio /= recognizer.scale
            if player.rate == 0 {
                setTimeline()
            }
        }
        recognizer.scale = 1
        
        if recognizer.state == .ended {
            isPinching = false
        }
    }
    
    @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        guard !audioView.zoomSamples.isEmpty, let duration = player.currentItem?.duration else { return }
        
        if recognizer.state == .began {
            isPaning = true
            wasPlaying = player.rate == 0 ? false : true
            player.pause()
        }
        
        let point = recognizer.translation(in: self)
        recognizer.setTranslation(CGPoint.zero, in: self)
        
        let samplesPerPixel = CGFloat(audioView.zoomSamples.count) / bounds.width
        let deltaPixels = point.x < 0
        ? min(-point.x * samplesPerPixel, CGFloat(audioView.totalSamples - audioView.zoomSamples.endIndex + offset))
        : min(point.x * samplesPerPixel, CGFloat(audioView.zoomSamples.startIndex + offset)) * -1
        let middle = (audioView.zoomSamples.startIndex + audioView.zoomSamples.endIndex) / 2
        let seekTo = CMTimeMakeWithSeconds(duration.seconds * Double(middle) / Double(audioView.totalSamples), preferredTimescale: PREFERED_SCALE)
        if deltaPixels != 0 {
            audioView.zoomSamples = audioView.zoomSamples.startIndex + Int(deltaPixels) ..< audioView.zoomSamples.endIndex + Int(deltaPixels)
            player.seek(to: seekTo)
        }
        if recognizer.state == .ended {
            player.seek(to: seekTo, toleranceBefore: .zero, toleranceAfter: .zero) {_ in
                self.isPaning = false
                if self.wasPlaying {
                    self.player.play()
                }
            }
            
        }
        
    }
}


