//
//  VideoEditorViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 4/23/23.
//

import AVFoundation
import UIKit
import MobileCoreServices

class VideoEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let movie = AVMutableComposition()
    let videoComposition = AVMutableVideoComposition()
    private let videoTrack: AVMutableCompositionTrack?
    private let audioTrack: AVMutableCompositionTrack?
    private var end = CMTime.zero
    
    private let player = AVPlayer()
    private var playerLayer: AVPlayerLayer?
    private let picker = UIImagePickerController()
    
    private let selectButton = UIButton()
    private let exportButton = UIButton()
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

    
    override func loadView() {
        super.loadView()
        let view = UIView()
        view.backgroundColor = .white
        
        selectButton.setTitle("select", for: .normal)
        selectButton.setTitleColor(.black, for: .normal)
        selectButton.addTarget(self, action: #selector(VideoEditorViewController.selectVideo), for: .touchUpInside)
        selectButton.layer.borderColor = UIColor.black.cgColor
        selectButton.layer.borderWidth = 1
        selectButton.layer.cornerRadius = 10
        view.addSubview(selectButton)
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        selectButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: LEFT_RIGHT_PADDING).isActive = true
        selectButton.topAnchor.constraint(equalTo: view.topAnchor, constant: TOP_PADDING).isActive = true
        selectButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        
        exportButton.setTitle("export", for: .normal)
        exportButton.setTitleColor(.black, for: .normal)
        exportButton.addTarget(self, action: #selector(VideoEditorViewController.removeTest), for: .touchUpInside)
        exportButton.layer.borderColor = UIColor.black.cgColor
        exportButton.layer.borderWidth = 1
        exportButton.layer.cornerRadius = 10
        view.addSubview(exportButton)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -LEFT_RIGHT_PADDING).isActive = true
        exportButton.topAnchor.constraint(equalTo: view.topAnchor, constant: TOP_PADDING).isActive = true
        exportButton.widthAnchor.constraint(equalToConstant: 60).isActive = true

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
    }
    
    @objc func selectVideo() {
        player.pause()
        present(picker, animated: true)
    }
    
    @objc func removeTest() {
        print(movie.duration)
        let timeRange = CMTimeRange(start: CMTimeMakeWithSeconds(2, preferredTimescale: 1000), duration: CMTimeMakeWithSeconds(5, preferredTimescale: 1000))
        videoTrack?.removeTimeRange(timeRange)
        audioTrack?.removeTimeRange(timeRange)
        print(movie.duration)
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
        
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        let playerItem = AVPlayerItem(asset: movie)
        
        playerItem.videoComposition = videoComposition
        player.replaceCurrentItem(with: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer!.frame = CGRect(x: 10, y: 50, width: view.frame.width-LEFT_RIGHT_PADDING*2, height: view.frame.height-50-TRACK_HEIGHT-LEFT_RIGHT_PADDING-TOP_PADDING)
        playerLayer!.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer!)
        player.play()
    }
}

