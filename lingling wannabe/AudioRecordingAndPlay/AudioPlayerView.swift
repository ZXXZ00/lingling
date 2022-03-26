//
//  AudioPlayerView.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 3/21/22.
//

import UIKit
import AVFoundation

class AudioPlayerView: UIView, AVAudioPlayerDelegate {
    var player: AVAudioPlayer?
    
    let slider = UISlider()
    let label = UILabel()
    let playPause = UIButton()
    let playPauseConfig = UIImage.SymbolConfiguration(textStyle: .largeTitle)
    let playIcon: UIImage?
    let pauseIcon: UIImage?
    
    var timer: Timer? = nil
    
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init() {
        playIcon = UIImage(systemName: "play.fill", withConfiguration: playPauseConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal)
        pauseIcon = UIImage(systemName: "pause.fill", withConfiguration: playPauseConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal)
        super.init(frame: .zero)
        backgroundColor = .lightGray
        initSubView()
        slider.alpha = 0
    }
    
    private func initSubView() {
        playPause.setImage(playIcon, for: .normal)
        playPause.addTarget(self, action: #selector(AudioPlayerView.togglePlaying), for: .touchUpInside)
        addSubview(playPause)
        playPause.translatesAutoresizingMaskIntoConstraints = false
        playPause.centerXAnchor.constraint(equalTo: leftAnchor, constant: 40).isActive = true
        playPause.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        playPause.widthAnchor.constraint(equalToConstant: 40).isActive = true
        playPause.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        label.textColor = .white
        label.font = UIFont(name: "AmericanTypewriter", size: 14)
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.rightAnchor.constraint(equalTo: rightAnchor, constant: -20).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        label.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        slider.minimumValue = 0
        slider.value = 0
        slider.isContinuous = true
        slider.addTarget(self, action: #selector(AudioPlayerView.seek), for: .valueChanged)
        addSubview(slider)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.leftAnchor.constraint(equalTo: playPause.rightAnchor, constant: 10).isActive = true
        slider.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        slider.rightAnchor.constraint(equalTo: label.leftAnchor, constant: -10).isActive = true
        slider.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    @objc func seek() {
        guard let player = player else { return }
        player.currentTime = Double(slider.value)
    }
    
    @objc func togglePlaying() {
        guard let player = player else {
            return
        }
        if player.isPlaying {
            pausePlaying()
            playPause.setImage(playIcon, for: .normal)
        } else {
            startPlaying()
            playPause.setImage(pauseIcon, for: .normal)
        }
    }
    
    func startPlaying() {
        guard let player = player else {
            return
        }
        player.play()
        let context = ["progress":"audioplay"]
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateProgress), userInfo: context, repeats: true)
        timer?.tolerance = 0.05
    }

    func pausePlaying() {
        timer?.invalidate()
        player?.pause()
    }
    
    func loadAudioAt(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            player.delegate = self
            player.prepareToPlay()
            
            playPause.setImage(playIcon, for: .normal)
            label.text = "\(timeToString(0))/\(timeToString(player.duration))"
            slider.value = 0
            slider.maximumValue = Float(player.duration)
            slider.alpha = 1
        } catch {
            // TODO: error handling
            print(error.localizedDescription)
        }
    }
    
    func timeToString(_ t: TimeInterval) -> String {
        let hour = Int(t) / 3600
        let minute = Int(t - Double(hour * 3600)) / 60
        let second = Int(t) % 60
        if hour == 0 {
            return String(format: "%02d:%02d", minute, second)
        } else {
            return String(format: "%d:%02d:%02d", hour, minute, second)
        }
    }
    
    @objc func updateProgress() {
        guard let player = player else { return }
        if !player.isPlaying { return }
        slider.value = Float(player.currentTime)
        label.text = "\(timeToString(player.currentTime))/\(timeToString(player.duration))"
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            slider.value = Float(player.duration)
            label.text = "\(timeToString(player.duration))/\(timeToString(player.duration))"
        }
        timer?.invalidate()
        playPause.setImage(playIcon, for: .normal)
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        // TODO: handle audio interruption
    }
}
