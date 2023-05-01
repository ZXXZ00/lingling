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
    private var videoTrack: AVMutableCompositionTrack?
    private var audioTrack: AVMutableCompositionTrack?
    private var end = CMTime.zero
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private let picker = UIImagePickerController()
    
    private let selectButton = UIButton()
    private let exportButton = UIButton()
    
    
    let WIDTH: CGFloat = 1080
    let HEIGHT: CGFloat = 1920
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        selectButton.frame = CGRect(x: 10, y: 10, width: 40, height: 30)
        selectButton.setTitle("select", for: .normal)
        selectButton.setTitleColor(.black, for: .normal)
        selectButton.addTarget(self, action: #selector(VideoEditorViewController.selectVideo), for: .touchUpInside)
        view.addSubview(selectButton)
        
        exportButton.frame = CGRect(x: 150, y: 10, width: 40, height: 30)
        exportButton.setTitle("export", for: .normal)
        exportButton.setTitleColor(.black, for: .normal)
        exportButton.addTarget(self, action: #selector(VideoEditorViewController.exportVideo), for: .touchUpInside)
        view.addSubview(exportButton)
        
        videoTrack = movie.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        audioTrack = movie.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        picker.sourceType = .photoLibrary
        picker.videoQuality = .typeHigh
        picker.videoExportPreset = AVAssetExportPresetHighestQuality
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.allowsEditing = true
        picker.delegate = self
        
        player = AVPlayer()
        videoComposition.instructions = []
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = CGSize(width: WIDTH, height: HEIGHT)
        
    }
    
    @objc func selectVideo() {
        present(picker, animated: true)
    }
    
    @objc func exportVideo() {
        let exporter = AVAssetExportSession(asset: movie, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = getDocumentDirectory().appendingPathComponent("april31.mov")
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
        }
        picker.dismiss(animated: true)
        
        playerLayer?.removeFromSuperlayer()
        let playerItem = AVPlayerItem(asset: movie)
        
        playerItem.videoComposition = videoComposition
        player?.replaceCurrentItem(with: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        print(view.frame)
        playerLayer!.frame = CGRect(x: 10, y: 50, width: view.frame.width-20, height: view.frame.height-200)
        playerLayer!.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer!)
        player?.play()
    }
}
