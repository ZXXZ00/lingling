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
        //slider.addTarget(self, action: #selector(PracticeViewController.refreshAnimation), for: .touchDown)
        label.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        label.text = "60"
        label.font = UIFont(name: "Arial", size: 24)
        label.textColor = UIColor(white: 0.5, alpha: 1)
        label.center = CGPoint(x: view.center.x/2, y: view.center.y/2-45)
        playButton.frame = CGRect(x: 0, y: 0, width: 45, height: 45)
        playButton.center = CGPoint(x: view.center.x*1.5, y: view.center.y/2-45)
        playButton.setImage(playImage, for: .normal)
        playButton.addTarget(self, action: #selector(PracticeViewController.playPause), for: .touchUpInside)
        //playButton.addTarget(self, action: #selector(PracticeViewController.refreshAnimation), for: .touchDown)
        view.addSubview(slider)
        view.addSubview(label)
        view.addSubview(playButton)
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.metronome = Metronome()
        }
    }
    
    //override func viewDidAppear(_ animated: Bool) {
    //    metronome = Metronome()
    //}
    
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
            label.text = String(bpm)
            metronome?.bpm = bpm
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}
