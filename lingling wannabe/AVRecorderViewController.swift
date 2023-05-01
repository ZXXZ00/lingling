//
//  AVRecorderViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 4/5/23.
//

import UIKit
import AVFoundation
import Photos

class AVRecorderViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    let captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var movieOutput: AVCaptureMovieFileOutput!
    let button = UIButton()
    var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        button.frame = CGRect(x: 10, y: 10, width: 40, height: 30)
        button.setTitle("test", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(AVRecorderViewController.toggleRecording), for: .touchUpInside)
        view.addSubview(button)
        
        captureSession.beginConfiguration()
        
        let videoDevice = AVCaptureDevice.default(for: .video)!
        let videoInput = try! AVCaptureDeviceInput(device: videoDevice)
        captureSession.addInput(videoInput)
        
        let audioDevice = AVCaptureDevice.default(for: .audio)!
        let audioInput = try! AVCaptureDeviceInput(device: audioDevice)
        captureSession.addInput(audioInput)
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = CGRect(x: 10, y: 100, width: 300, height: 300)
        view.layer.addSublayer(videoPreviewLayer)
        
        movieOutput = AVCaptureMovieFileOutput()
        captureSession.addOutput(movieOutput)
        captureSession.commitConfiguration()
        captureSession.startRunning()
        
        
    }
    
    private func configureSession() {
        captureSession.beginConfiguration()
        let videoDevice = AVCaptureDevice.default(for: .video)
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
              captureSession.canAddInput(videoDeviceInput) else {
            return
        }
    }
    
    @objc func toggleRecording() {
        if isRecording {
            movieOutput.stopRecording()
            isRecording = false
            
        } else {
            // Start recording
            let outputPath = NSTemporaryDirectory() + "movie.mov"
            let outputURL = URL(fileURLWithPath: outputPath)
            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
            isRecording = true
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
        } else {
            print(outputFileURL)
            // Save video to Photos library
//            PHPhotoLibrary.shared().performChanges({
//                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
//            }) { success, error in
//                if let error = error {
//                    print("Error saving video to Photos library: \(error.localizedDescription)")
//                } else {
//                    print("Video saved to Photos library!")
//                }
//            }
        }
    }
}
