//
//  VideoEditorViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 4/23/23.
//

import AVFoundation
import AVKit
import UIKit
import MobileCoreServices

class VideoEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let movie = AVMutableComposition()
    let videoComposition = AVMutableVideoComposition()
    private let videoTrack: AVMutableCompositionTrack?
    private let audioTrack: AVMutableCompositionTrack?
    private var end = CMTime.zero
    
    private let player = AVPlayer()
    private let picker = UIImagePickerController()
    private let playerView = UIView()
    
    private let testvc = AVPlayerViewController()
    
    private let selectButton = UIButton()
    private let exportButton = UIButton()
    private let backButton = UIButton()
    private let trackViewController: TrackViewController
    
    private var assets: [UIView] = []
    
    let WIDTH: CGFloat = 1080
    let HEIGHT: CGFloat = 1920
    let TRACK_HEIGHT: CGFloat = 80
    let LEFT_RIGHT_PADDING: CGFloat = 10
    let TOP_PADDING: CGFloat = 8
    let BOT_PADDING: CGFloat = 10
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init() {
        trackViewController = TrackViewController(player: player)
        
        videoTrack = movie.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        audioTrack = movie.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        super.init(nibName: nil, bundle: nil)
        
        picker.sourceType = .photoLibrary
        picker.videoQuality = .typeHigh
        picker.videoExportPreset = AVAssetExportPresetHighestQuality
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.allowsEditing = true
        picker.delegate = self
        
        videoComposition.instructions = []
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = CGSize(width: WIDTH, height: HEIGHT)
    }

    private func styleButton(button: UIButton, text: String) {
        button.setTitle(text, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 10
    }
    
    override func loadView() {
        super.loadView()
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        
        backButton.addTarget(self, action: #selector(VideoEditorViewController.back), for: .touchUpInside)
        styleButton(button: backButton, text: "back")
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: LEFT_RIGHT_PADDING).isActive = true
        backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: TOP_PADDING).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        
        exportButton.addTarget(self, action: #selector(VideoEditorViewController.exportVideo), for: .touchUpInside)
        styleButton(button: exportButton, text: "export")
        view.addSubview(exportButton)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -LEFT_RIGHT_PADDING).isActive = true
        exportButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: TOP_PADDING).isActive = true
        exportButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        
        selectButton.addTarget(self, action: #selector(VideoEditorViewController.selectVideo), for: .touchUpInside)
        styleButton(button: selectButton, text: "select")
        view.addSubview(selectButton)
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        selectButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -LEFT_RIGHT_PADDING).isActive = true
        selectButton.topAnchor.constraint(equalTo: exportButton.bottomAnchor, constant: BOT_PADDING).isActive = true
        selectButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        
        view.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: TOP_PADDING).isActive = true
        playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -BOT_PADDING-TRACK_HEIGHT).isActive = true
        playerView.leftAnchor.constraint(equalTo: backButton.rightAnchor, constant: LEFT_RIGHT_PADDING).isActive = true
        playerView.rightAnchor.constraint(equalTo: exportButton.leftAnchor, constant: -LEFT_RIGHT_PADDING).isActive = true
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(trackViewController)
        view.addSubview(trackViewController.view)
        trackViewController.view.translatesAutoresizingMaskIntoConstraints = false
        trackViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor, constant: LEFT_RIGHT_PADDING).isActive = true
        trackViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -BOT_PADDING).isActive = true
        trackViewController.view.heightAnchor.constraint(equalToConstant: TRACK_HEIGHT).isActive = true
        trackViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2*LEFT_RIGHT_PADDING).isActive = true
        trackViewController.didMove(toParent: self)
        
        testvc.player = player
        addChild(testvc)
        view.addSubview(testvc.view)
        testvc.view.translatesAutoresizingMaskIntoConstraints = false
        testvc.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: TOP_PADDING).isActive = true
        testvc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -BOT_PADDING-TRACK_HEIGHT).isActive = true
        testvc.view.leftAnchor.constraint(equalTo: backButton.rightAnchor, constant: LEFT_RIGHT_PADDING).isActive = true
        testvc.view.rightAnchor.constraint(equalTo: exportButton.leftAnchor, constant: -LEFT_RIGHT_PADDING).isActive = true
        testvc.didMove(toParent: self)
    }
    
    @objc func selectVideo() {
        player.pause()
        present(picker, animated: true)
    }
    
    @objc func back() {
        presentingViewController?.dismiss(animated: true)
    }
    
    @objc func exportVideo() {
        player.pause()
        let exporter = AVAssetExportSession(asset: movie, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = getDocumentDirectory().appendingPathComponent("may10.mov")
        exporter?.outputFileType = .mov
        exporter?.videoComposition = videoComposition
        exporter?.exportAsynchronously {
            print("export finished")
            print(exporter?.status.rawValue)
            print(exporter?.error)
        }
    }
    
    // copied from https://stackoverflow.com/questions/25104232/merge-two-videos-in-ios-app-still-maintain-the-orientation-of-each-video
    // and https://www.kodeco.com/10857372-how-to-play-record-and-merge-videos-in-ios-and-swift
    func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
    func calculateRatio(width: CGFloat, height: CGFloat) -> CGFloat {
        let widthRatio = WIDTH / width
        let heightRatio = HEIGHT / height
        
        // return min because we need to satisfies the longest side
        // e.g. width = 1920 height = 1080, WIDTH: 1080 HEIGHT: 1920
        // we need to make sure width is included: 1080 / 1920 < 1920 / 1080
        return min(widthRatio, heightRatio)
    }
    
    func videoCompositionInstruction(
        track: AVCompositionTrack,
        asset: AVAsset,
        start: CMTime,
        duration: CMTime
    ) -> AVMutableVideoCompositionInstruction {
        let instruction = AVMutableVideoCompositionInstruction()
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video).first!
                
        let transform =  assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform: transform)
        
        if assetInfo.isPortrait {
            // assume natraulSize.width is height and vice versa
            let ratio = calculateRatio(width: assetTrack.naturalSize.height, height: assetTrack.naturalSize.width)
            layerInstruction.setTransform(transform.concatenating(CGAffineTransform(scaleX: ratio, y: ratio)), at: start)
        } else {
            let ratio = calculateRatio(width: assetTrack.naturalSize.width, height: assetTrack.naturalSize.height)
            // for landscape we need to translate Y down so the video is in the center
            let deltaY = HEIGHT / 2 - assetTrack.naturalSize.height * ratio / 2
            layerInstruction.setTransform(transform.concatenating(CGAffineTransform(scaleX: ratio, y: ratio)).concatenating(CGAffineTransform(translationX: 0, y: deltaY)), at: start)
        }
        instruction.layerInstructions = [layerInstruction]
        instruction.timeRange = CMTimeRangeMake(start: start, duration: duration)
        return instruction
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let url = info[.mediaURL] as? URL {
            let asset = AVURLAsset(url: url)
            let assetRange = CMTimeRangeMake(start: .zero, duration: asset.duration)
            do {
                try audioTrack?.insertTimeRange(assetRange, of: asset.tracks(withMediaType: .audio).first!, at: end)
                try videoTrack?.insertTimeRange(assetRange, of: asset.tracks(withMediaType: .video).first!, at: end)
                let instruction = videoCompositionInstruction(track: videoTrack!, asset: asset, start: end, duration: asset.duration)
                videoComposition.instructions.append(instruction)
                end = CMTimeAdd(end, asset.duration)
            } catch {
                print(error.localizedDescription)
            }
            trackViewController.loadAsset(asset: asset, assetRange: assetRange)
        }
        picker.dismiss(animated: true)
//        trackView.loadAsset(asset: movie)
        
        let playerItem = AVPlayerItem(asset: movie)
        playerItem.videoComposition = videoComposition
        player.replaceCurrentItem(with: playerItem)
        print(testvc.view.frame, testvc.videoBounds, testvc.view.bounds)
        player.play()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}

