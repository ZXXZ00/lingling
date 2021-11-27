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
    
    let serialQueue = DispatchQueue(label: "MainView", qos: .userInteractive)
    var nav: LeaderBoardNavigation!
    var username = UserDefaults.standard.string(forKey: "username") ?? "guest"
    var dataStatus = 0
    
    override func loadView() {
        let mainView = MainView(frame: UIScreen.main.bounds, user: username, controller: self)
        mainView.backgroundColor = .white
        self.view = mainView
        
        let itemWidth = (42 * view.frame.width / 360).rounded()
        let width = itemWidth*7+6
        nav = LeaderBoardNavigation(size: CGSize(width: width, height: view.frame.height*0.8))
    }
    
    override func viewDidLoad() {
        // TODO: Add intro animation and dismiss it after a delay
        serialQueue.async {
            self.dataStatus = DataManager.shared.checkAndLoad(username: self.username, time: Date().timeIntervalSince1970)
            if self.dataStatus == 0 {
                DataManager.shared.sync()
            }
        }
        
        //let tmp = loadPoints(filename: "whole")
        //
        //for m in tmp {
        //    let f = FourierSeries(real: m["x"]!, imag: m["y"]!, position: CGPoint(x: 0, y: 50))
        //    f.addTrace()
        //    view.layer.addSublayer(f.layer)
        //}
        //let anim = createAnimation(name: "whole")
        //anim.position = CGPoint(x: view.center.x - 150, y: view.center.y-150)
        //view.layer.addSublayer(anim)

    }
    
    func checkData() {
        serialQueue.async {
            DispatchQueue.main.async {
                if self.dataStatus == 1 {
                    let alert = UIAlertController(title: "Warning", message: "There is a data corruption!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                } else if self.dataStatus == 2 {
                    // it is possible the system time is not right
                    // TODO: check time with server then notify the user if there is a data corruption or time is off
                    let alert = UIAlertController(title: "Warning", message: "Data corruption or inaccurate time!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let user = UserDefaults.standard.string(forKey: "username") {
            username = user
            if let mainView = view as? MainView {
                mainView.username.setTitle(username, for: .normal)
            }
        } else {
            let signup = LoginViewController(CGSize(width: view.frame.width, height: view.frame.height), isFullScreen: true)
            present(signup, animated: false)
        }
        
        checkData()
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
        DataManager.shared.addRecord(username: username, time: start, duration: span, asset: asset)
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
        print(username)
        let userinfoView = UserInfoViewController(CGSize(width: width, height: width*4/3), username: username)
        present(userinfoView, animated: true, completion: nil)
        serialQueue.async {
            DispatchQueue.main.async {
                userinfoView.loadData()
            }
        }
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

