//
//  TrackAsset.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/18/23.
//

import AVFoundation

class TrackAsset {
    private var _asset: AVAsset
    private var _assetTimeRange: CMTimeRange
    private var _trackTimeRange: CMTimeRange
    // assetTimeRange is the timeRange of the asset it self
    // trackTimeRange is the timeRange of the asset on the track
    
    var asset: AVAsset {
        get {
            return _asset
        }
    }
    var assetTimeRange: CMTimeRange {
        get {
            return _assetTimeRange
        }
    }
    var trackTimeRange: CMTimeRange {
        get {
            return _trackTimeRange
        }
    }
    
    init(asset: AVAsset, assetTimeRange: CMTimeRange, trackTimeRange: CMTimeRange) {
        _asset = asset
        _assetTimeRange = assetTimeRange
        _trackTimeRange = trackTimeRange
    }
}

