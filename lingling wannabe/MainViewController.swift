//
//  MainViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 1/24/21.
//

import AVFoundation
import UIKit
import PocketSVG
import MobileCoreServices
import Toast_Swift

class MainViewController: UIViewController {
    
    let serialQueue = DispatchQueue(label: "MainView", qos: .userInteractive)
    var nav: LeaderBoardNavigation!
    private var previousUsername = CredentialManager.shared.getUsername()
    var username : String {
        get {
            let ret = CredentialManager.shared.getUsername()
            if ret != previousUsername {
                logOut()
            }
            return ret
        }
    }
    var dataStatus: DataStatus = .success {
        didSet {
            checkData()
        }
    }
    
    override func loadView() {
        let mainView = MainView(frame: UIScreen.main.bounds, user: username, controller: self)
        mainView.backgroundColor = .white
        self.view = mainView
        
        let itemWidth = (42 * view.frame.width / 360).rounded()
        let width = itemWidth*7+6
        nav = LeaderBoardNavigation(size: CGSize(width: width, height: view.frame.height*0.8))
    }
    
    func changeUser(user: String) {
        previousUsername = user
        DispatchQueue.main.async {
            if let mainView = self.view as? MainView {
                mainView.username.setTitle(user, for: .normal)
            }
        }
    }
    
    func showLoginViewController() {
        let signup = LoginViewController(CGSize(width: view.frame.width, height: view.frame.height), isFullScreen: true, didRegister: {
            [weak self] user in
            self?.changeUser(user: user)
            DataManager.shared.sync(username: user, token: CredentialManager.shared.getToken())
            DispatchQueue.main.async {
                let instruments = InstrumentSelectionViewController(style: .plain)
                instruments.didSelected = {
                    DispatchQueue.main.async {
                        (self?.view as? MainView)?.addTutorialView()
                    }
                }
                self?.addChild(instruments)
                self?.view.addSubview(instruments.view)
                if let layoutGuide = self?.view.safeAreaLayoutGuide {
                    instruments.view.translatesAutoresizingMaskIntoConstraints = false
                    instruments.view.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor).isActive = true
                    instruments.view.centerYAnchor.constraint(equalTo: layoutGuide.centerYAnchor).isActive = true
                    instruments.view.widthAnchor.constraint(equalTo: layoutGuide.widthAnchor).isActive = true
                    instruments.view.heightAnchor.constraint(equalTo: layoutGuide.heightAnchor).isActive = true
                }
                instruments.didMove(toParent: self)
            }
        }, didLogin: {
            [weak self] user in
            self?.changeUser(user: user)
            DataManager.shared.sync(username: user, token: CredentialManager.shared.getToken())
        }, didContinueAsGuest: {
            [weak self] in
            self?.changeUser(user: "guest")
            DispatchQueue.main.async {
                (self?.view as? MainView)?.addTutorialView()
            }
        })
        addChild(signup)
        view.addSubview(signup.view)
        signup.didMove(toParent: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if username == "guest" {
            showLoginViewController()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.resetData), name: DataManager.ConflictNotification, object: nil)
        
        let intro = UIView()
        intro.backgroundColor = UIColor.white
        intro.frame = view.frame
        let content = highlightAnimate(name: "treble", duration: 19)
        content.bounds = CGRect(x: 0, y: 0, width: 300, height: 300)
        content.position = view.center
        let scale = min(intro.frame.width, intro.frame.height) / 300
        content.transform = CATransform3DMakeScale(scale, scale, 1)
        intro.layer.addSublayer(content)
        view.addSubview(intro)
        let introTime = 2.0
        
        serialQueue.async {
            let token = CredentialManager.shared.getToken()
            self.dataStatus = DataManager.shared.checkAndLoad(username: self.username, token: token)
        }
        UIView.animate(withDuration: 1, delay: introTime, animations: {
            intro.alpha = 0
        }, completion: {finished in
            intro.removeFromSuperview()
        })
        
    }
    
    func checkData() {
        serialQueue.async {
            DispatchQueue.main.async {
                if self.dataStatus == .conflict {
                    let alert = UIAlertController(title: "Warning", message: "There is a data corruption!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: self.resetDataHandler))
                    self.present(alert, animated: true)
                } else if self.dataStatus == .future {
                    // it is possible the system time is not right
                    // TODO: check time with server then notify the user if there is a data corruption or time is off
                    let alert = UIAlertController(title: "Warning", message: "Data corruption or inaccurate time!\nCheck your Time Setting!\nIf time is correct, reset data!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: self.resetDataHandler))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    private func resetDataHandler(alert: UIAlertAction) {
        resetDataHelper()
    }
    
    @objc func resetData() {
        print("notification received")
        dataStatus = .conflict
    }
    
    private func resetDataHelper() {
        print("reset data")
        DataManager.shared.clear()
        CalendarData.cache.removeAll()
        CalendarData.cacheTime.removeAll()
        DataManager.shared.downloadRecord(username: username)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        serialQueue.async {
            DataManager.shared.sync(username: self.username, token: CredentialManager.shared.getToken())
        }
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
        var span = duration
        var asset = assetName
        let percentage = ResultDelegate.shared.musicPercentage(cutoff: ResultDelegate.cutoff)
        if  percentage < ResultDelegate.percentage {
            span = -duration
            asset = assetName + "_rest"
        }
        serialQueue.async {
            DataManager.shared.addRecord(username: self.username, time: start, duration: span, asset: asset, attributes: "{\"music\": \(percentage)}", upload: true)
        }
        if username == "guest" {
            FilesManager.shared.upload(username: UUID().uuidString, time: Int(Date().timeIntervalSince1970))
        } else {
            FilesManager.shared.upload(username: username, time: start)
        }
    }
    
    @objc func startAnalyze() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.mixWithOthers, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("failed to set active")
            print(error)
        }
        
        ResultDelegate.shared.reset()
        if !checkMicrophone() {
            print("nan")
            return
        }
        
        var delay: Int = 15*60
        if let mainView = view as? MainView {
            delay = mainView.minutes * 60
        } else {
            print("failed to cast view as MainView")
            return
        }
        let start = Date().timeIntervalSince1970
        let practiceView = PracticeViewController(duration: delay) {
            DispatchQueue.main.async {
                let mainview = self.view as! MainView
                mainview.showResult()
                self.handleResult(start: Int(start), duration: Int(delay), assetName: mainview.currSymbol)
                print(ResultDelegate.shared.test())
                print("time","end", "music","bg")
//                ResultDelegate.shared.print_()
            }
        }
        practiceView.modalPresentationStyle = .fullScreen
        present(practiceView, animated: true)
    }
    
    @objc func showUserInfo() {
        // 42 * 7 + 6 = 300, so the cell can all fit into a week with 1 being the margin between
        let itemWidth = (42 * view.frame.width / 360).rounded()
        let width = itemWidth*7+6
        let userinfoView = UserInfoViewController(CGSize(width: width, height: width*4/3), username: username)
        present(userinfoView, animated: true, completion: nil)
        serialQueue.async {
            DataManager.shared.sync(username: self.username, token: CredentialManager.shared.getToken())
            DispatchQueue.main.async {
                userinfoView.loadData()
            }
        }
    }
    
    func showRecordings(isRecording: Bool) {
        let itemWidth = (42 * view.frame.width / 360).rounded()
        let width = itemWidth*7+6
        let recordings = RecordingViewController(
            size: CGSize(width: width, height: view.frame.height*0.7),
            username: CredentialManager.shared.getUsername(),
            isRecording: isRecording)
        present(recordings, animated: true)
    }
    
    func showRecordToast() {
        
    }
    
    func showVideoCamera() {
        let videoTaker = UIImagePickerController()
        videoTaker.sourceType = .camera
        videoTaker.mediaTypes = [kUTTypeMovie as String]
        videoTaker.videoQuality = .typeHigh
        videoTaker.allowsEditing = true
        videoTaker.videoExportPreset = AVAssetExportPresetHEVCHighestQuality
        present(videoTaker, animated: true)
    }
    
    @objc func showVideoEditor() {
        let videoEditor = VideoEditorViewController()
        videoEditor.modalPresentationStyle = .fullScreen
        present(videoEditor, animated: true)
    }
    
    @objc func showLeaderBoard() {
        nav.isToolbarHidden = true
        present(nav, animated: true, completion: nil)
    }
    
    @objc func showDebug() {
//        let debugV = DebugViewController()
//        debugV.modalPresentationStyle = .formSheet
//        present(debugV, animated: true)
        //let testV = AVRecorderViewController()
        //present(testV, animated: true)
        
        let tt = UIImagePickerController()
        tt.sourceType = .camera
        tt.mediaTypes = [kUTTypeMovie as String]
        tt.videoQuality = .typeHigh
        tt.allowsEditing = true
        tt.videoExportPreset = AVAssetExportPresetHEVCHighestQuality
        tt.delegate = self
        present(tt, animated: true)
    }
    
    @objc func showSetting() {
        let setting = SettingNavigation(size: CGSize(width: view.frame.width * 0.8, height: 120), settingDelegate: self)
        present(setting, animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.darkContent
    }
}

extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let url = info[.mediaURL] as? URL {
            saveToPhoto(source: url, view: view)
        }
        picker.dismiss(animated: true)
    }
}

extension MainViewController: SettingDelegate {
    
    func logOut() {
        CredentialManager.shared.delete()
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                self.showLoginViewController()
            }
        }
    }
}

