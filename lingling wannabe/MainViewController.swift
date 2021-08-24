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
    
    override func loadView() {
        let mainView = MainView(frame: UIScreen.main.bounds, controller: self)
        mainView.backgroundColor = .white
        self.view = mainView
    }
    
    override func viewDidLoad() {
        DataManager.shared.test()
        // TODO: Add intro animation and dismiss it after a delay
        
        //let url = URL(string: "https://j7by90n61a.execute-api.us-east-1.amazonaws.com/record?username=adam")
        //getJSON(url: url!, success: {_ in}, failure: {_ in})
        //let baseurl = URL(string: "https://j7by90n61a.execute-api.us-east-1.amazonaws.com/record")
        //let adam: [String: Any] = ["username": "adam", "records": [["time": 1627434964, "duration": 60]]]
        //postJSON(url: baseurl!, json: adam, success: {_, _ in}, failure: {_ in})
        //getJSON(url: url!, success: {_ in}, failure: {_ in})
        //let laohuang = ["username": "laozhang", "password": "password", "email": "laozhang@test.com"]
        //postJSON(url: url!, json: laohuang as [String: Any], success: {_, _ in}, failure: {_ in})
        //postJSON(url: url!, json: laohuang as [String: Any], success: {_, _ in}, failure: {_ in})
        //postJSON(url: url!, json: laohuang, success: {_, _ in}, failure: {_ in})
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
        let practiceView = PracticeViewController()
        practiceView.modalPresentationStyle = .fullScreen
        present(practiceView, animated: true, completion: {
            AudioStreamAnalyzer.shared.analyze()
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            AudioStreamAnalyzer.shared.stop()
            self.dismiss(animated: true, completion: nil)
            (self.view as! MainView).showResult()
            print(ResultDelegate.shared.test())
            print("time","end", "music","bg")
            ResultDelegate.shared.print_()
        }
    }
    
    @objc func showUserInfo() {
        let itemWidth = (42 * view.frame.width / 360).rounded()
        let width = itemWidth*7+6
        let userinfoView = UserInfoViewController(CGSize(width: width, height: width*4/3))
        present(userinfoView, animated: true, completion: nil)
        //let nav = LeaderBoardNavigation(size: CGSize(width: width, height: width*4/2.5))
        //nav.isToolbarHidden = true
        //present(nav, animated: true, completion: nil)
        //let loginView = LoginViewController(CGSize(width: width, height: width*4/3))
        //present(loginView, animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.darkContent
    }

}

