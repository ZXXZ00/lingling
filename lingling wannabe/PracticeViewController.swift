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
    let label = UILabel()
    let playImage = UIImage(named: "play")
    let pauseImage = UIImage(named: "pause")
    let countdown = UILabel()
    var completion: (() -> Void)? = nil
    var duration: Int? = nil
    var timer: Timer? = nil
    
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
        
        label.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        label.text = "60"
        label.font = UIFont(name: "Arial", size: 24)
        label.textColor = UIColor(white: 0.5, alpha: 1)
        label.center = CGPoint(x: view.center.x/2, y: view.center.y/2-45)
        
        playButton.frame = CGRect(x: 0, y: 0, width: 45, height: 45)
        playButton.center = CGPoint(x: view.center.x*1.5, y: view.center.y/2-45)
        playButton.setImage(playImage, for: .normal)
        playButton.addTarget(self, action: #selector(PracticeViewController.playPause), for: .touchUpInside)
        
        countdown.textAlignment = .center
        countdown.textColor = UIColor(white: 0.5, alpha: 1)
        view.addSubview(countdown)
        countdown.translatesAutoresizingMaskIntoConstraints = false
        countdown.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        countdown.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        countdown.widthAnchor.constraint(equalToConstant: 80).isActive = true
        countdown.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(slider)
        view.addSubview(label)
        view.addSubview(playButton)
        
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.metronome = Metronome()
        }
        if let _ = duration {
            let context = ["countdown":"practice"]
            let timer = Timer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: context, repeats: true)
            timer.tolerance = 0.1
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    @objc func updateTimer() {
        if let remaining = duration {
            duration = remaining - 1
            if duration! < 0 { return }
            let minutes = duration!/60
            let seconds = duration! - minutes*60
            if seconds < 10 {
                countdown.text = "\(minutes):0\(seconds)"
            } else {
                countdown.text = "\(minutes):\(seconds)"
            }
        }
    }
    
    //override func viewDidAppear(_ animated: Bool) {
    //    metronome = Metronome()
    //}
    
    override func viewWillDisappear(_ animated: Bool) {
        metronome?.destroy()
        timer?.invalidate()
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
            label.text = String(bpm)
            metronome?.bpm = bpm
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}
