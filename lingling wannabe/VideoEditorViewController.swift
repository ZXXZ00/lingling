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
import Photos
import Toast_Swift

class VideoEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let movie = AVMutableComposition()
    private var videoComposition = AVMutableVideoComposition()
    private let videoTrack: AVMutableCompositionTrack?
    private let audioTrack: AVMutableCompositionTrack?
    private var end = CMTime.zero
    
    private let player = AVPlayer()
    private var playerLayer: AVPlayerLayer?
    private let picker = UIImagePickerController()
    
    private let playerViewController = AVPlayerViewController()
    private let playerViewWidthConstraint: NSLayoutConstraint
    
    private let trackViewController: TrackViewController
    
    private let toolBarView = ToolBarView()
        
    let WIDTH: CGFloat = 1080
    let HEIGHT: CGFloat = 1920
    let TRACK_HEIGHT: CGFloat = 80
    
    let LEFT_RIGHT_PADDING: CGFloat = 10
    let TOP_PADDING: CGFloat = 8
    static let BOT_PADDING: CGFloat = 10
    static let TOOLBAR_WIDTH: CGFloat = 60
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init() {
        trackViewController = TrackViewController(player: player)
        
        videoTrack = movie.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        audioTrack = movie.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        playerViewWidthConstraint = playerViewController.view.widthAnchor.constraint(equalToConstant: 0)
        
        super.init(nibName: nil, bundle: nil)
        
        picker.sourceType = .photoLibrary
        picker.videoQuality = .typeHigh
        picker.videoExportPreset = AVAssetExportPresetPassthrough
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
        view.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        
        toolBarView.controller = self
        view.addSubview(toolBarView)
        toolBarView.translatesAutoresizingMaskIntoConstraints = false
        toolBarView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: LEFT_RIGHT_PADDING).isActive = true
        toolBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: TOP_PADDING).isActive = true
        toolBarView.widthAnchor.constraint(equalToConstant: VideoEditorViewController.TOOLBAR_WIDTH).isActive = true
        toolBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -VideoEditorViewController.BOT_PADDING-TRACK_HEIGHT).isActive = true
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        trackViewController.delegate = self
        addChild(trackViewController)
        view.addSubview(trackViewController.view)
        trackViewController.view.translatesAutoresizingMaskIntoConstraints = false
        trackViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor, constant: LEFT_RIGHT_PADDING).isActive = true
        trackViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -VideoEditorViewController.BOT_PADDING).isActive = true
        trackViewController.view.heightAnchor.constraint(equalToConstant: TRACK_HEIGHT).isActive = true
        trackViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2*LEFT_RIGHT_PADDING).isActive = true
        trackViewController.didMove(toParent: self)
        
        playerViewController.player = player
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        playerViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: TOP_PADDING).isActive = true
        playerViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -VideoEditorViewController.BOT_PADDING-TRACK_HEIGHT).isActive = true
        playerViewController.view.leftAnchor.constraint(equalTo: toolBarView.rightAnchor, constant: LEFT_RIGHT_PADDING).isActive = true
        playerViewController.view.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -LEFT_RIGHT_PADDING).isActive = true
        playerViewController.view.backgroundColor = .none
        playerViewController.allowsPictureInPicturePlayback = false
        
        playerViewController.didMove(toParent: self)
    }
    
    @objc func selectVideo() {
        player.pause()
        present(picker, animated: true)
    }
    
    @objc func back() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        presentingViewController?.dismiss(animated: true)
    }
    
    @objc func exportVideo() {
        player.pause()
        let exporter = AVAssetExportSession(asset: movie, presetName: AVAssetExportPresetHighestQuality)
        let url = getDocumentDirectory().appendingPathComponent("\(Date().timeIntervalSince1970).mov")
        exporter?.outputURL = url
        exporter?.outputFileType = .mov
        exporter?.exportAsynchronously {
            if (exporter?.status == .completed) {
                self.saveToPhoto(source: url)
            } else {
                self.view.makeToast("Failed to export: \(exporter?.error?.localizedDescription ?? "")")
                DataManager.shared.insertErrorMessage(isNetwork: false, message: "Failed to export: \(exporter?.error?.localizedDescription ?? "")")
            }
        }
    }
    
    func saveToPhoto(source: URL) {
        PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: source) }) {
            success, error in
            if success {
                self.view.makeToast("Saved to Photos")
            } else {
                self.view.makeToast("Failed to save: \(error?.localizedDescription ?? "")")
                DataManager.shared.insertErrorMessage(isNetwork: false, message: "Failed to save: \(error?.localizedDescription ?? "")")
            }
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
    
    func reloadPlayer() {
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        let playerItem = AVPlayerItem(asset: movie)
//        playerItem.videoComposition = videoComposition
        player.replaceCurrentItem(with: playerItem)
        // IDK why creating AVPlayerLayer works
        // but if I delete the line, the playback will only be video+audio of first item and audio for the rest
        playerLayer = AVPlayerLayer(player: player)
        //playerLayer!.frame = playerViewController.view.bounds
        //playerViewController.view.layer.addSublayer(playerLayer!)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let url = info[.mediaURL] as? URL {
            let asset = AVURLAsset(url: url)
            let assetRange = CMTimeRangeMake(start: .zero, duration: asset.duration)
            let aTrack = asset.tracks(withMediaType: .audio).first!
            let vTrack = asset.tracks(withMediaType: .video).first!
            if orientationFromTransform(transform: vTrack.preferredTransform).isPortrait {
                videoTrack?.preferredTransform = vTrack.preferredTransform
            } else {
                picker.dismiss(animated: true)
                view.makeToast("Please Select Video in Potrait Orientation", position: .center)
                return
            }
            do {
                try audioTrack?.insertTimeRange(assetRange, of: aTrack, at: end)
                try videoTrack?.insertTimeRange(assetRange, of: vTrack, at: end)
//                let instruction = videoCompositionInstruction(track: videoTrack!, asset: asset, start: end, duration: asset.duration)
//                videoComposition.instructions.append(instruction)
                end = CMTimeAdd(end, asset.duration)
            } catch {
                print(error.localizedDescription)
            }
            trackViewController.loadAsset(asset: asset, assetRange: assetRange)
        }
        picker.dismiss(animated: true)
        
        reloadPlayer()
        
        player.play()
    }
    
    @objc func deleteAsset() {
        guard let removed = trackViewController.deleteSelected() else { return }
        player.pause()
        movie.removeTimeRange(removed)
//        videoComposition = videoComposition.removeTimeRange(removed)
        end = CMTimeSubtract(end, removed.duration)
        reloadPlayer()
    }
    
    @objc func trimAsset() {
        guard let (left, right) = trackViewController.trim() else { return }
        player.pause()
        // must delete right first
        // otherwise deleting left will change the section right should delete
        movie.removeTimeRange(right)
        movie.removeTimeRange(left)
        end = CMTimeSubtract(end, left.duration + right.duration)
        reloadPlayer()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}

extension VideoEditorViewController: TrackViewControllerDelegate {
    
    func didSelectView(view: TrackItemView) {
        toolBarView.deleteButton.alpha = 1
        toolBarView.checkButton.alpha = 1
    }
    
    func didUnselect() {
        toolBarView.deleteButton.alpha = 0
        toolBarView.checkButton.alpha = 0
    }
}

extension AVMutableVideoComposition {
    func removeTimeRange(_ timeRange: CMTimeRange) -> AVMutableVideoComposition {
        var newInstructions: [AVVideoCompositionInstruction] = []
        var subtract: CMTime = .zero
        
        for instruction in instructions {
            guard let instr = instruction as? AVVideoCompositionInstruction else { continue }
            if timeRange.containsTimeRange(instruction.timeRange) {
                subtract = timeRange.duration
                continue
            }
            let newInstruction = AVMutableVideoCompositionInstruction()
            if instruction.timeRange.containsTimeRange(timeRange) {
                subtract = timeRange.duration
                newInstruction.layerInstructions = instr.layerInstructions
                newInstruction.timeRange = CMTimeRange(start: instruction.timeRange.start, duration: instruction.timeRange.duration - subtract)
            }
            // for the case where ...[.....cut_start...],[....],[...]....[...cut_end...].....
            else if instruction.timeRange.containsTime(timeRange.start) {
                newInstruction.layerInstructions = instr.layerInstructions
                newInstruction.timeRange = CMTimeRange(start: instruction.timeRange.start, end: timeRange.start)
                subtract = timeRange.duration
            } else if instruction.timeRange.containsTime(timeRange.end) {
                newInstruction.layerInstructions = instr.layerInstructions
                newInstruction.timeRange = CMTimeRange(start: timeRange.end - subtract, end: instruction.timeRange.end - subtract)
            } else {
                newInstruction.layerInstructions = instr.layerInstructions
                newInstruction.timeRange = CMTimeRange(start: instruction.timeRange.start - subtract, duration: instruction.timeRange.duration)
            }
            newInstructions.append(newInstruction)
        }
        
        let ret = AVMutableVideoComposition()
        ret.frameDuration = frameDuration
        ret.renderSize = renderSize
        ret.instructions = newInstructions
        return ret
    }
}
