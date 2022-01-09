//
//  PracticeViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/2/21.
//

import UIKit

class PracticeViewController : UIViewController {
    
    // TO DO for production: Error Handling for metronome it is optional type
    var metronome : Metronome!
    let slider = UISlider()
    let playButton = UIButton()
    let speed = UILabel()
    let playImage = UIImage(named: "play")
    let pauseImage = UIImage(named: "pause")
    let countdown = UILabel()
    let label = UILabel()
    
    var completion: (() -> Void)? = nil
    var remaining: Int
    var timer: Timer? = nil
    
    let analyzer = AudioStreamAnalyzer()
    
    init(duration: Int, block: (() -> Void)? = nil) {
        completion = block
        remaining = duration
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        slider.frame = CGRect(x: 0, y: 0, width: view.frame.width*0.7, height: view.frame.width*0.1)
        slider.minimumValue = 40
        slider.maximumValue = 200
        slider.value = 60
        slider.thumbTintColor = UIColor(white: 0.45, alpha: 1)
        slider.minimumTrackTintColor = UIColor(white: 0.3, alpha: 1)
        slider.maximumTrackTintColor = UIColor(white: 0.15, alpha: 1)
        slider.center = CGPoint(x: view.center.x, y: view.center.y/2)
        slider.addTarget(self, action: #selector(PracticeViewController.changeMetronome), for: .valueChanged)
        
        speed.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        speed.text = "60"
        speed.font = UIFont(name: "AmericanTypewriter", size: 24)
        speed.textColor = UIColor(white: 0.5, alpha: 1)
        speed.center = CGPoint(x: view.center.x/2, y: view.center.y/2-45)
        
        label.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 60)
        label.textAlignment = .center
        label.font = UIFont(name: "AmericanTypewriter", size: 20)
        label.textColor = UIColor(white: 0.5, alpha: 1)
        label.center = view.center
        
        playButton.frame = CGRect(x: 0, y: 0, width: 45, height: 45)
        playButton.center = CGPoint(x: view.center.x*1.5, y: view.center.y/2-45)
        playButton.setImage(playImage, for: .normal)
        playButton.addTarget(self, action: #selector(PracticeViewController.playPause), for: .touchUpInside)
        
        countdown.textAlignment = .center
        countdown.font = UIFont(name: "AmericanTypewriter", size: 17)
        countdown.textColor = UIColor(white: 0.5, alpha: 1)
        view.addSubview(countdown)
        countdown.translatesAutoresizingMaskIntoConstraints = false
        countdown.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        countdown.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        countdown.widthAnchor.constraint(equalToConstant: 80).isActive = true
        countdown.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(slider)
        view.addSubview(speed)
        view.addSubview(label)
        view.addSubview(playButton)
        
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.metronome = Metronome()
        }
        
        let context = ["countdown":"practice"]
        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: context, repeats: true)
        timer!.tolerance = 0.01
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    @objc func updateTimer() {
        if ResultDelegate.shared.isPracticing {
            label.text = "\(ResultDelegate.shared.debugP)\n"
        } else {
            label.text = "\(ResultDelegate.shared.debugP)\nSounds like you are not practicing!"
        }
        remaining -= 1
        if remaining < 0 {
            timer?.invalidate()
            timer = nil
            analyzer.stop()
            if let f = completion {
                f()
            }
            dismiss(animated: true)
            return
        }
        let minutes = remaining/60
        let seconds = remaining - minutes*60
        if seconds < 10 {
            countdown.text = "\(minutes):0\(seconds)"
        } else {
            countdown.text = "\(minutes):\(seconds)"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        analyzer.analyze()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        metronome?.destroy()
    }
    
    @objc func playPause() {
        if metronome!.isPlaying {
            playButton.setImage(playImage, for: .normal)
            metronome?.pause()
        } else {
            playButton.setImage(pauseImage, for: .normal)
            metronome?.start()
        }
    }
    
    @objc func changeMetronome() {
        let bpm = Int(slider.value)
        if bpm != metronome?.bpm {
            speed.text = String(bpm)
            metronome?.bpm = bpm
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}
