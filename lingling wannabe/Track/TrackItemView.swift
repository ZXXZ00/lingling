//
//  TrackItemView.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/16/23.
//

import UIKit
import AVFoundation

class TrackItemView: FDWaveformView {
    
    static let BORDER_WIDTH: CGFloat = 1
    var index = 0
    
    let editView = FDWaveformView()
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init(asset: AVAsset, size: CGSize) {
        super.init(frame: .zero)
        loadAsset(asset: asset)
        doesAllowScrubbing = false
        doesAllowStretch = false
        doesAllowScroll = false
        waveformType = .linear
        wavesColor = TrackViewController.DEFAULT_WAVE_COLOR
        backgroundColor = TrackViewController.DEFAULT_BG_COLOR
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = TrackItemView.BORDER_WIDTH
        isUserInteractionEnabled = false
        
        editView.loadAsset(asset: asset)
        editView.doesAllowScrubbing = false
        editView.doesAllowStretch = false
        editView.doesAllowScroll = false
        editView.wavesColor = .white
        editView.progressColor = UIColor(red: 0.6, green: 0.66, blue: 0.56, alpha: 1)
        editView.waveformType = .linear
        editView.frame = CGRect(x: TrackViewController.HANDLE_WIDTH, y: 0, width: size.width - 2*TrackViewController.HANDLE_WIDTH, height: size.height)
    }
}
