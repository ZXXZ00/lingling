//
//  PracticeViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/2/21.
//

import UIKit
import AVFAudio

class PracticeViewController : UIViewController {
    
    var metronome : Metronome?
    let slider = UISlider()
    let playButton = UIButton()
    let speed = UILabel()
    let playImage = UIImage(named: "play")
    let pauseImage = UIImage(named: "pause")
    let countdown = UILabel()
    let label = UILabel()
    let abortButton = UIButton()
    let abortCountdown = UILabel()
    
    var completion: (() -> Void)? = nil
    let duration: Int
    var timeElapsed: Double = 0
    var timer: Timer? = nil
    var abortRemaining = 30
    
    var analyzer = AudioStreamAnalyzer()
    
    let durationLimit = 60 * 60 // 1 hour
    
    private var isSuspended = false
    
    init(duration: Int, block: (() -> Void)? = nil) {
        completion = block
        self.duration = duration
        super.init(nibName: nil, bundle: nil)
        if duration > durationLimit {
            analyzer.isWritingToFile = false
        }
        registerForAVAudioSessionNotifications()
        DispatchQueue.global(qos: .userInteractive).async {
            self.metronome = Metronome()
            DispatchQueue.main.async {
                self.registerForAVAudioEngineNotifications()
            }
        }
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
        
        label.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 80)
        label.textAlignment = .center
        label.numberOfLines = 3
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
        
        abortButton.setTitle("Abort", for: .normal)
        abortButton.titleLabel?.font = UIFont(name: "AmericanTypewriter", size: 20)
        abortButton.setTitleColor(UIColor(white: 0.6, alpha: 1), for: .normal)
        abortButton.layer.borderWidth = 1
        abortButton.layer.cornerRadius = 10
        abortButton.layer.borderColor = UIColor(white: 0.6, alpha: 1).cgColor
        view.addSubview(abortButton)
        abortButton.translatesAutoresizingMaskIntoConstraints = false
        abortButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        abortButton.centerYAnchor.constraint(equalTo: view.bottomAnchor, constant: -100).isActive = true
        abortButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        abortButton.heightAnchor.constraint(equalToConstant: 64).isActive = true
        abortButton.addTarget(self, action: #selector(abortWarning), for: .touchUpInside)
        
        abortCountdown.textAlignment = .center
        abortCountdown.font = UIFont(name: "AmericanTypewriter", size: 15)
        abortCountdown.textColor = UIColor(white: 0.6, alpha: 1)
        abortButton.addSubview(abortCountdown)
        abortCountdown.translatesAutoresizingMaskIntoConstraints = false
        abortCountdown.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        abortCountdown.centerYAnchor.constraint(equalTo: abortButton.topAnchor, constant: 12).isActive = true
        abortCountdown.widthAnchor.constraint(equalToConstant: 100).isActive = true
        abortCountdown.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        view.addSubview(slider)
        view.addSubview(speed)
        view.addSubview(label)
        view.addSubview(playButton)
        
        let context = ["countdown":"practice"]
        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: context, repeats: true)
        timer?.tolerance = 0.1
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    @objc func updateTimer() {
        if ResultDelegate.shared.isPracticing {
            //label.text = "\(ResultDelegate.shared.debugP)\n"
            label.text = ""
        } else {
            //label.text = "\(ResultDelegate.shared.debugP)\nSounds like you are not practicing!"
            label.text = "Sounds like you are not practicing!\n(The recognition might be wrong)\n(If it is wrong, ignore it)"
        }
        timeElapsed += analyzer.timeDelta()
        let remaining = duration - Int(timeElapsed)
        if abortRemaining > 0 {
            abortRemaining -= 1
            if abortRemaining > 9 {
                abortCountdown.text = "00:\(abortRemaining)"
            } else {
                abortCountdown.text = "00:0\(abortRemaining)"
            }
        } else if abortRemaining == 0 {
            abortButton.removeFromSuperview()
        }
        if remaining < 0 {
            timer?.invalidate()
            timer = nil
            analyzer.stop()
            if let f = completion {
                f()
            }
            presentingViewController?.dismiss(animated: true)
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
    
    @objc func abortWarning() {
        let alert = UIAlertController(title: "Abort Session", message: "Are you sure you want to abort current session?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Abort", style: .default) { _ in
            self.analyzer.stop()
            self.presentingViewController?.dismiss(animated: true)
        })
        self.present(alert, animated: true)
    }
    
    func registerForAVAudioSessionNotifications(){
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) {
            [weak self] (notification) in
            guard let weakself = self,
                  let userInfo = notification.userInfo,
                  let interruptionTypeValue: UInt = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeValue)
            else { return }
            
            switch interruptionType {
            case .began:
                print("interruption started")
                weakself.analyzer.pause()
                weakself.metronome?.pause()
                weakself.playButton.setImage(weakself.playImage, for: .normal)
                weakself.isSuspended = true
            case .ended:
                print("interruption ended")
                do {
                    //try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.mixWithOthers, .defaultToSpeaker])
                    try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                    try weakself.analyzer.startAudioEngine()
                    try weakself.metronome?.startEngine()
                } catch {
                    print("Failed after interruption")
                    print(error.localizedDescription)
                }
                weakself.isSuspended = false
            @unknown default:
                break
            }
        }
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) {
            [weak self] (notification) in
            guard let weakself = self,
                  let userInfo = notification.userInfo,
                  let reasonValue: UInt = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
            else { return }
            
            print("route change, reason: \(reason)")
        }
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) {
            [weak self] (notification) in
            print("media service reset")
            guard let weakself = self else { return }
            if !weakself.isSuspended {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.mixWithOthers, .defaultToSpeaker])
                    try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                    weakself.analyzer = AudioStreamAnalyzer()
                    weakself.metronome = Metronome()
                    weakself.unRegisterForAVaAudioEngineNotifications()
                    weakself.registerForAVAudioEngineNotifications()
                    try weakself.analyzer.analyze()
                } catch {
                    print("failed to recover from media service reset: \(error)")
                }
            }
        }
    }
    
    func registerForAVAudioEngineNotifications() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVAudioEngineConfigurationChange, object: analyzer.audioEngine, queue: .main) {
            [weak self] (notification) in
            guard let weakself = self else { return }
            print("AVAudioEngine Configuration Change")
            if !weakself.isSuspended {
                do {
                    try weakself.analyzer.startAudioEngine()
                } catch {
                    print("fail to start analyzer audio engine: \(error)")
                }
            }
        }
        
        guard let met = metronome else { return }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVAudioEngineConfigurationChange, object: met.engine, queue: .main) {
            [weak self] (notification) in
            guard let weakself = self else { return }
            print("AVAudioEngine Configuration Change")
            if !weakself.isSuspended {
                do {
                    try weakself.metronome?.startEngine()
                } catch {
                    print("fail to start analyzer audio engine: \(error)")
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        do {
            try analyzer.analyze()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        metronome?.destroy()
        timer?.invalidate()
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("faild to set avaudio session to false")
            print(error)
        }
    }
    
    func unRegisterForAVaAudioEngineNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVAudioEngineConfigurationChange, object: analyzer.audioEngine)
        guard let met = metronome else { return }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVAudioEngineConfigurationChange, object: met.engine)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        unRegisterForAVaAudioEngineNotifications()
    }
    
    @objc func playPause() {
        guard let metronome = metronome else { return}

        if metronome.isPlaying {
            playButton.setImage(playImage, for: .normal)
            metronome.pause()
        } else {
            do {
                try metronome.start()
                playButton.setImage(pauseImage, for: .normal)
            } catch {
                DataManager.shared.insertErrorMessage(isNetwork: false, message: "couldn't start motronome: \(error)")
                print(error)
            }
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
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}
