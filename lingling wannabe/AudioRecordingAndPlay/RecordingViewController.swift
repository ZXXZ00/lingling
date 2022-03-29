//
//  RecordingViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 3/19/22.
//

import UIKit
import AVFoundation

class RecordingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AudioRecorderDelegate {
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
    
    let formatter = DateFormatter()
    
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
        let allFiles: [String]
        do {
            var yes: ObjCBool = true
            if !FileManager.default.fileExists(atPath: folder.path, isDirectory: &yes) {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            }
            allFiles = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        } catch {
            // TODO: add error handling
            allFiles = []
            print(error.localizedDescription)
        }
        
        recordingView = AudioRecorderView(path: tmp)
        
        formatter.dateFormat = "yyyy-MM-dd"
        
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = floatViewDelegate
        
        allFiles.forEach {
            addFileToList(filename: $0)
        }
    }
    
    func addFileToList(filename: String) {
        if filename.count < 5 { return }
        let idx = filename.index(filename.endIndex, offsetBy: -5)
        let str = String(filename[..<idx])
        if let t = Double(str) {
            let date = formatter.string(from: Date(timeIntervalSince1970: t))
            counter[date, default: 0] += 1
            if (counter[date]! > 1) {
                let name = "\(date)_\(counter[date]! - 1)"
                displayNames.append(name)
                filesMap[name] = filename
            } else {
                displayNames.append(date)
                filesMap[date] = filename
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "FilesCell", for: indexPath)
        cell.textLabel?.textColor = .black
        cell.textLabel?.text = displayNames[indexPath.row]
        cell.backgroundColor = cell.isSelected ? UIColor(white: 0.9, alpha: 1) : .white
        let bgView = UIView()
        bgView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        cell.selectedBackgroundView = bgView
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        guard let displayName = cell?.textLabel?.text,
              let filename = filesMap[displayName] else { return }
        controlView.loadAudioAt(url: folder.appendingPathComponent(filename))
    }
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .none
        
        filesView.delegate = self
        filesView.dataSource = self
        filesView.register(UITableViewCell.self, forCellReuseIdentifier: "FilesCell")
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
        let utc = String(format: "%d.flac", Int(Date().timeIntervalSince1970))
        do {
            try FileManager.default.moveItem(at: tmp, to: folder.appendingPathComponent(utc))
        } catch {
            print(error.localizedDescription)
            // TODO: error handling
        }
        saveButton.removeFromSuperview()
        recordingView.removeFromSuperview()
        
        let idx = IndexPath(row: displayNames.count, section: 0)
        addFileToList(filename: utc)
        filesView.insertRows(at: [idx], with: .automatic)
        filesView.selectRow(at: idx, animated: false, scrollPosition: .bottom)
    }
    
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
