//
//  RecordingViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 3/19/22.
//

import UIKit
import AVFoundation

class RecordingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let size: CGSize
    let floatViewDelegate: FloatView
    
    let filesView = UITableView()
    let controlView = AudioPlayerView()
    let recordingView: AudioRecorderView
    let saveButton = UIButton()
    
    let CONTROLVIEW_HEIGHT: CGFloat = 60
    let isRecording: Bool
    
    let folder: URL
    let tmp: URL
    var displayNames: [String] = []
    var counter: [String:Int] = [:]
    var filesMap: [String:String] = [:] // map displayNames to actual file name
    var labelMap: [String:String] = [:] // map files to label
    
    let formatter = DateFormatter()
    
    let audioLabelView = AudioLabelView()
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init(size: CGSize, username: String, isRecording: Bool) {
        self.isRecording = isRecording
        self.size = size
        floatViewDelegate = FloatView(size)
        
        let bytes: [UInt8] = Array(username.utf8)
        let usernameHex = bytes.compactMap { String(format: "%02x", $0) }.joined()
        folder = getDocumentDirectory().appendingPathComponent("recordings/\(usernameHex)")
        tmp = folder.appendingPathComponent("tmp.flac")
        
        recordingView = AudioRecorderView(path: tmp)
        
        formatter.dateFormat = "yyyy-MM-dd"
        
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = floatViewDelegate
        
        registerForAudioInterruption()
        
        var labels = Set<String>()
        let res = FilesManager.shared.getLabels(username: CredentialManager.shared.getUsername())
        res.forEach {
            // $0 is filename, $1 is label
            labelMap[$0] = $1
            labels.insert($1)
        }
        audioLabelView.suggestionsArray = Array(labels)
        audioLabelView.controller = self
        
        populate()
    }
    
    // populate the arrays and maps used for tableview data such as displayNames filesMap
    func populate() {
        var allFiles: [String]
        do {
            var yes: ObjCBool = true
            if !FileManager.default.fileExists(atPath: folder.path, isDirectory: &yes) {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            }
            allFiles = try FileManager.default.contentsOfDirectory(atPath: folder.path)
            allFiles.sort()
        } catch {
            // TODO: add error handling
            allFiles = []
            DataManager.shared.insertErrorMessage(isNetwork: false, message: "Failed to create folder: \(error)")
            print("Failed to create folder: \(error)")
        }
        
        allFiles.forEach {
            addFileToList(filename: $0)
        }
    }

    func addFileToList(filename: String, label: String?=nil) {
        if filename.count < 5 { return }
        let idx = filename.index(filename.endIndex, offsetBy: -5)
        let str = String(filename[..<idx])
        if let t = Double(str) {
            let date = formatter.string(from: Date(timeIntervalSince1970: t))
            counter[date, default: 0] += 1
            let key: String
            if (counter[date]! > 1) {
                key = "\(date)_\(counter[date]! - 1)"
            } else {
                key = date
            }
            displayNames.append(key)
            filesMap[key] = filename
            if let l = labelMap[str] {
                labelMap[key] = l
            } else if let l = label {
                labelMap[key] = l
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        controlView.pausePlaying()
        recordingView.stopRecording()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FilesCell", for: indexPath) as! AudioFileCell
        cell.fileName.textColor = .black
        cell.fileName.text = displayNames[indexPath.row]
        if let label = labelMap[displayNames[indexPath.row]] {
            cell.labelName.text = label
        }
        cell.backgroundColor = cell.isSelected ? UIColor(white: 0.9, alpha: 1) : .white
        let bgView = UIView()
        bgView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        cell.selectedBackgroundView = bgView
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? AudioFileCell
        guard let displayName = cell?.fileName.text,
              let filename = filesMap[displayName] else { return }
        controlView.loadAudioAt(url: folder.appendingPathComponent(filename))
    }
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .none
        
        filesView.delegate = self
        filesView.dataSource = self
        filesView.register(AudioFileCell.self, forCellReuseIdentifier: "FilesCell")
        filesView.rowHeight = 44
        filesView.separatorStyle = .none
        view.addSubview(filesView)
        filesView.backgroundColor = .white
        filesView.translatesAutoresizingMaskIntoConstraints = false
        filesView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        filesView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        filesView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        filesView.heightAnchor.constraint(equalTo: view.heightAnchor, constant: -CONTROLVIEW_HEIGHT).isActive = true
        
        if (isRecording) {
            recordingView.delegate = self
            view.addSubview(recordingView)
            recordingView.translatesAutoresizingMaskIntoConstraints = false
            recordingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            recordingView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            recordingView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
            recordingView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
            controlView.alpha = 0
            
            saveButton.setImage(UIImage(named: "save_file.pdf"), for: .normal)
            saveButton.addTarget(self, action: #selector(RecordingViewController.saveFile), for: .touchUpInside)
            view.addSubview(saveButton)
            saveButton.translatesAutoresizingMaskIntoConstraints = false
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            saveButton.widthAnchor.constraint(equalTo: recordingView.button.widthAnchor, multiplier: 1.34).isActive = true
            saveButton.heightAnchor.constraint(equalTo: recordingView.button.widthAnchor, multiplier: 1.34).isActive = true
            NSLayoutConstraint(item: saveButton, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.4, constant: 0).isActive = true
            saveButton.alpha = 0
        }
        
        view.addSubview(controlView)
        controlView.translatesAutoresizingMaskIntoConstraints = false
        controlView.topAnchor.constraint(equalTo: filesView.bottomAnchor).isActive = true
        controlView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        controlView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        controlView.heightAnchor.constraint(equalToConstant: CONTROLVIEW_HEIGHT).isActive = true
        
        self.view = view
    }
    
    @objc func saveFile() {
        let time = Int(Date().timeIntervalSince1970)
        let utc = String(format: "%d.flac", time)
        do {
            try FileManager.default.copyItem(at: tmp, to: folder.appendingPathComponent(utc))
        } catch {
            print("Failed to move file: \(error)")
            // TODO: error handling
            DataManager.shared.insertErrorMessage(isNetwork: false, message: "Failed to move file: \(error)")
        }
        
        audioLabelView.audioFileTime = time
        view.addSubview(audioLabelView)
        audioLabelView.translatesAutoresizingMaskIntoConstraints = false
        audioLabelView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        audioLabelView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        audioLabelView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        audioLabelView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        
        saveButton.removeFromSuperview()
        recordingView.removeFromSuperview()
    }
    
    func updateAndInsertRow(filename: String, label: String?=nil) {
        let idx = IndexPath(row: displayNames.count, section: 0)
        addFileToList(filename: filename, label: label)
        filesView.insertRows(at: [idx], with: .automatic)
        filesView.selectRow(at: idx, animated: false, scrollPosition: .bottom)
    }
    
    func registerForAudioInterruption() {
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
                let recorder = weakself.recordingView
                let player = weakself.controlView
                if (weakself.isRecording && recorder.isRecording()) {
                    weakself.recordingView.toggleRecording()
                } else if player.isPlaying() {
                    player.togglePlaying()
                }
            case .ended:
                print("interruption ended")
            @unknown default:
                break
            }
        }
    }
}

extension RecordingViewController: AudioRecorderDelegate {
    
    func didBegin() {
        controlView.pausePlaying()
        controlView.alpha = 0
        saveButton.alpha = 0
    }
    
    func didFinish() {
        controlView.alpha = 1
        saveButton.alpha = 1
        controlView.loadAudioAt(url: tmp)
    }
    
}
