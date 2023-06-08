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
    
    func trackSubtract(_ time: CMTime) {
        _trackTimeRange = CMTimeRange(start: _trackTimeRange.start - time, end: _trackTimeRange.end - time)
    }
    
    // start and end are relatvie to asset's own timerange
    // return (the_timerange_needed to be deleted on the left, ... on the right) in track time
    func trim(start: CMTime, end: CMTime) -> (CMTimeRange, CMTimeRange)? {
        let newTimeRange = CMTimeRange(start: start, end: end)
        if !_assetTimeRange.containsTimeRange(newTimeRange)
            || _assetTimeRange == newTimeRange {
            return nil
        }
        let left = start - _assetTimeRange.start
        let right = _assetTimeRange.end - end
        let ret = (CMTimeRange(start: _trackTimeRange.start, duration: left), CMTimeRange(start: _trackTimeRange.end - right, duration: right))
        _trackTimeRange = CMTimeRange(start: _trackTimeRange.start, duration: end - start)
        _assetTimeRange = newTimeRange
        return ret
    }
}

