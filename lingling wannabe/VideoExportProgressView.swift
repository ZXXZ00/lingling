//
//  VideoExportProgressView.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 7/11/23.
//

import UIKit
import AVFoundation

class VideoExportProgressView: UIView {
    
    let progressBar = UIProgressView()
    let cancelButton = UIButton()
    weak var delegate: VideoExportProgressViewDelegate?
    let exporter: AVAssetExportSession
    var timer: Timer?
    
    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }
    
    init(exporter: AVAssetExportSession) {
        self.exporter = exporter
        super.init(frame: .zero)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        
        addSubview(progressBar)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        progressBar.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -40).isActive = true
        progressBar.heightAnchor.constraint(equalToConstant: 8).isActive = true
        progressBar.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6).isActive = true
        
        progressBar.setProgress(0.5, animated: true)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.red, for: .normal)
        cancelButton.layer.borderColor = UIColor.red.cgColor
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.cornerRadius = 10
        
        addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        cancelButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 40).isActive = true
        cancelButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        cancelButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.progressBar.setProgress(self.exporter.progress, animated: true)
            }
        }
        timer?.tolerance = 0.5
    }
    
    deinit {
        print("deinit")
        timer?.invalidate()
    }
    
    @objc func cancel() {
        delegate?.didCancel(progressView: self, exporter: exporter)
    }
    
}

protocol VideoExportProgressViewDelegate: AnyObject {
    func didCancel(progressView: VideoExportProgressView, exporter: AVAssetExportSession)
}
