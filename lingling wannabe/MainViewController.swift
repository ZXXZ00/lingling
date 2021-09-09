//
//  MainViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 1/24/21.
//

import AVFoundation
import UIKit
import PocketSVG

class MainViewController: UIViewController {
    
    let practiceQueue = DispatchQueue(label: "practicing")
    var nav: LeaderBoardNavigation!
    var username = UserDefaults.standard.string(forKey: "username") ?? "guest"
    
    override func loadView() {
        let mainView = MainView(frame: UIScreen.main.bounds, user: username, controller: self)
        mainView.backgroundColor = .white
        self.view = mainView
        
        let itemWidth = (42 * view.frame.width / 360).rounded()
        let width = itemWidth*7+6
        nav = LeaderBoardNavigation(size: CGSize(width: width, height: view.frame.height*0.8))
    }
    
    override func viewDidLoad() {
        if DataManager.shared.checkAndLoad(username: username, time: Date().timeIntervalSince1970) != 0 {
            // TODO: show user warning
            return
        }
        //DataManager.shared.test()
        //print(DataManager.shared.getRecord(username: "lingling"))
        //print(CalendarData.cache)
        //DataManager.shared.sync()
        // TODO: Add intro animation and dismiss it after a delay
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("hi")
        if let user = UserDefaults.standard.string(forKey: "username") {
            username = user
            if let mainView = view as? MainView {
                mainView.username.setTitle(username, for: .normal)
            }
        } else {
            let signup = LoginViewController(CGSize(width: view.frame.width, height: view.frame.height), isFullScreen: true)
            present(signup, animated: false)
        }
    }

    func loadTestView() {
        let start = UIButton(type: .system)
        start.setTitle("start", for: .normal)
        start.addTarget(AudioStreamAnalyzer.shared, action: #selector(AudioStreamAnalyzer.analyze), for: .touchUpInside)
        start.frame = CGRect(x:view.center.x, y:view.center.y-50, width:100, height: 50)
        let stop = UIButton(type: .system)
        stop.setTitle("stop", for: .normal)
        stop.addTarget(AudioStreamAnalyzer.shared, action: #selector(AudioStreamAnalyzer.stop), for: .touchUpInside)
        stop.frame = CGRect(x:view.center.x, y: view.center.y+50, width: 100, height: 50)
        let test = UIButton(type: .system)
        test.setTitle("print", for: .normal)
        test.addTarget(ResultDelegate.shared, action: #selector(ResultDelegate.print_), for: .touchUpInside)
        test.frame = CGRect(x: view.center.x, y: view.center.y, width: 100, height: 50)
        test.center = view.center
        view.addSubview(start)
        view.addSubview(stop)
        view.addSubview(test)
    }
    
    private func openSetting(alert: UIAlertAction) {
        if let url = URL.init(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func askForMicrophone() {
        let alert = UIAlertController(title: "Microphone Access", message: "Please grant access to microphone", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: openSetting))
        present(alert, animated: true)
    }
    
    private func checkMicrophone() -> Bool {
        var ret = false
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({
                granted in
                if granted {
                    ret = true
                } else {
                    DispatchQueue.main.async {
                        self.askForMicrophone()
                    }
                }
            })
        case .denied:
            askForMicrophone()
        default:
            ret = true
        }
        return ret
    }
    
    func handleResult(start: Int, duration: Int, assetName: String) {
        //guard let username = UserDefaults.standard.string(forKey: "username") else { return }
        var span = duration
        var asset = assetName
        if ResultDelegate.shared.musicPercentage(cutoff: ResultDelegate.cutoff) < ResultDelegate.percentage {
            span = -duration
            asset = assetName + "_rest"
        }
        DataManager.shared.addRecord(username: username, time: start, duration: span, assset: asset)
    }
    
    @objc func startAnalyze() {
        if !checkMicrophone() {
            print("nan")
            return
        }
        var delay : Double = 15*60
        if let mainView = view as? MainView {
            delay = mainView.minutes * 60
        } else {
            print("failed to cast view as MainView")
            return
        }
        let start = Date().timeIntervalSince1970
        let practiceView = PracticeViewController()
        practiceView.modalPresentationStyle = .fullScreen
        present(practiceView, animated: true, completion: {
            AudioStreamAnalyzer.shared.analyze()
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            AudioStreamAnalyzer.shared.stop()
            self.dismiss(animated: true, completion: nil)
            let mainview = self.view as! MainView
            mainview.showResult()
            self.handleResult(start: Int(start), duration: Int(delay), assetName: mainview.currSymbol)
            print(ResultDelegate.shared.test())
            print("time","end", "music","bg")
            ResultDelegate.shared.print_()
        }
    }
    
    @objc func showUserInfo() {
        // 42 * 7 + 6 = 300, so the cell can all fit into a week with 1 being the margin between
        let itemWidth = (42 * view.frame.width / 360).rounded()
        let width = itemWidth*7+6
        let userinfoView = UserInfoViewController(CGSize(width: width, height: width*4/3), username: username)
        present(userinfoView, animated: true, completion: nil)
        //let nav = LeaderBoardNavigation(size: CGSize(width: width, height: width*4/2.5))
        //nav.isToolbarHidden = true
        //present(nav, animated: true, completion: nil)
        //let loginView = LoginViewController(CGSize(width: width, height: width*4/3))
        //present(loginView, animated: true, completion: nil)
    }
    
    @objc func showLeaderBoard() {
        nav.isToolbarHidden = true
        present(nav, animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.darkContent
    }

}

