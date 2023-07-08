//
//  TrackViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/14/23.
//

import UIKit
import AVFoundation
import AVKit

class TrackViewController: UIViewController {
    
    private let player: AVPlayer
    var itemWidth: CGFloat = 40 {
        didSet {
            widthConstraint.constant = itemWidth * CGFloat(trackView.arrangedSubviews.count)
        }
    }
    weak var delegate: TrackViewControllerDelegate?
    
    let editContainerView = UIView()
    let leftHandleView = UIImageView()
    let rightHandleView = UIImageView()
    private var currentEditView: FDWaveformView? = nil {
        didSet {
            oldValue?.removeFromSuperview()
            if let editView = currentEditView {
                editContainerView.addSubview(editView)
                leftHandleView.alpha = 1
                editContainerView.bringSubviewToFront(leftHandleView)
                rightHandleView.alpha = 1
                editContainerView.bringSubviewToFront(rightHandleView)
            } else {
                leftHandleView.alpha = 0
                rightHandleView.alpha = 0
            }
        }
    }
    
    let trackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = -TrackItemView.BORDER_WIDTH
        view.distribution = .fillEqually
        return view
    }()
    
    let trackScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    
    private let widthConstraint: NSLayoutConstraint
    private let leftHandleConstraint: NSLayoutConstraint
    private let rightHandleConstraint: NSLayoutConstraint
    private var _selectedView: TrackItemView? = nil {
        didSet {
            guard oldValue?.index != _selectedView?.index else { return }
            oldValue?.backgroundColor = TrackViewController.DEFAULT_BG_COLOR
            _selectedView?.backgroundColor = UIColor(red: 0.75, green: 0.5, blue: 0.5, alpha: 1)
            currentEditView = _selectedView?.editView
            if let selected = _selectedView {
                delegate?.didSelectView(view: selected)
            } else {
                delegate?.didUnselect()
            }
        }
    }
    var selectedView: TrackItemView? {
        get { return _selectedView }
    }
    private var currentPlayingView: TrackItemView? = nil {
        didSet {
            guard oldValue?.index != currentPlayingView?.index else { return }
            oldValue?.wavesColor = TrackViewController.DEFAULT_WAVE_COLOR
            currentPlayingView?.wavesColor = UIColor(red: 0.4, green: 0.42, blue: 0.43, alpha: 1)
        }
    }
    private var playerObservers: [Any] = []
    
    private var assets: [TrackAsset] = []
    
    static let HANDLE_WIDTH: CGFloat = 16
    
    static let DEFAULT_BG_COLOR = UIColor(red: 0.7176, green: 0.7176, blue: 0.7176, alpha: 1)
    static let DEFAULT_WAVE_COLOR: UIColor = .white

    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init(player: AVPlayer) {
        self.player = player
        widthConstraint = trackView.widthAnchor.constraint(equalToConstant: 0)
        leftHandleConstraint = leftHandleView.rightAnchor.constraint(equalTo: editContainerView.leftAnchor)
        rightHandleConstraint = rightHandleView.leftAnchor.constraint(equalTo: editContainerView.leftAnchor)
        super.init(nibName: nil, bundle: nil)
        playerObservers.append(self.player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 5), queue: .main) { [weak self] _ in
            self?.updateCurrentPlayingItem()
        })
        playerObservers.append(self.player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30), queue: .main) {
            [weak self] _ in
            self?.updateEditViewProgress()
        })
    }
    
    private func setUpEditView() {
        view.addSubview(editContainerView)
        editContainerView.translatesAutoresizingMaskIntoConstraints = false
        editContainerView.translatesAutoresizingMaskIntoConstraints = false
        editContainerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        editContainerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        editContainerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        editContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5).isActive = true
        
        let backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        
        leftHandleView.image = UIImage(systemName: "lessthan")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        leftHandleView.backgroundColor = backgroundColor
        editContainerView.addSubview(leftHandleView)
        leftHandleView.translatesAutoresizingMaskIntoConstraints = false
        leftHandleView.widthAnchor.constraint(equalToConstant: TrackViewController.HANDLE_WIDTH).isActive = true
        leftHandleView.heightAnchor.constraint(equalTo: editContainerView.heightAnchor).isActive = true
        leftHandleConstraint.isActive = true
        leftHandleView.alpha = 0
        leftHandleView.isUserInteractionEnabled = true
        let leftPan = UIPanGestureRecognizer(target: self, action: #selector(handleLeftHandlerPan))
        leftHandleView.addGestureRecognizer(leftPan)
        
        rightHandleView.image = UIImage(systemName: "greaterthan")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        rightHandleView.backgroundColor = backgroundColor
        editContainerView.addSubview(rightHandleView)
        rightHandleView.translatesAutoresizingMaskIntoConstraints = false
        rightHandleView.widthAnchor.constraint(equalToConstant: TrackViewController.HANDLE_WIDTH).isActive = true
        rightHandleView.heightAnchor.constraint(equalTo: editContainerView.heightAnchor).isActive = true
        rightHandleConstraint.isActive = true
        rightHandleView.alpha = 0
        rightHandleView.isUserInteractionEnabled = true
        let rightPan = UIPanGestureRecognizer(target: self, action: #selector(handleRightHandlerPan))
        rightHandleView.addGestureRecognizer(rightPan)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpEditView()
                
        view.addSubview(trackScrollView)
        trackScrollView.translatesAutoresizingMaskIntoConstraints = false
        trackScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        trackScrollView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5).isActive = true
        trackScrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        trackScrollView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        
        trackScrollView.addSubview(trackView)
        trackView.translatesAutoresizingMaskIntoConstraints = false
        trackView.bottomAnchor.constraint(equalTo: trackScrollView.bottomAnchor).isActive = true
        trackView.topAnchor.constraint(equalTo: trackScrollView.topAnchor).isActive = true
        trackView.leftAnchor.constraint(equalTo: trackScrollView.leftAnchor).isActive = true
        trackView.rightAnchor.constraint(equalTo: trackScrollView.rightAnchor).isActive = true
        widthConstraint.isActive = true
        
        trackScrollView.contentSize = CGSize(width: view.frame.width, height: 0)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTouch))
        trackView.addGestureRecognizer(tapGesture)
    }
    
    private func calculateZoomSamples(asset: TrackAsset, totalSamples: Int) -> Range<Int> {
        let duration = asset.asset.duration.seconds
        let start = asset.assetTimeRange.start.seconds / duration
        let end = asset.assetTimeRange.end.seconds / duration
                
        return Int(start*Double(totalSamples)) ..< Int(end*Double(totalSamples))
    }
    
    @objc func handleTouch(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: trackView)
        _selectedView = get_selectedView(in: location)
        guard let _selectedView = _selectedView else {
            return
        }
        let asset = assets[_selectedView.index]
        _selectedView.editView.zoomSamples = calculateZoomSamples(asset: asset, totalSamples: _selectedView.editView.totalSamples)
        
        leftHandleConstraint.constant = TrackViewController.HANDLE_WIDTH
        rightHandleConstraint.constant = editContainerView.frame.width - TrackViewController.HANDLE_WIDTH
    }
    
    private func get_selectedView(in location: CGPoint) -> TrackItemView? {
        for subview in trackView.arrangedSubviews {
            if subview.frame.contains(location) {
                return subview as? TrackItemView
            }
        }
        return nil
    }
    
    @objc func handleRightHandlerPan(_ recognizer: UIPanGestureRecognizer) {
        player.pause()
        let translation = recognizer.translation(in: editContainerView)
        let newX = rightHandleConstraint.constant + translation.x
        if newX >= leftHandleConstraint.constant && newX <= editContainerView.frame.width - TrackViewController.HANDLE_WIDTH {
            rightHandleConstraint.constant = newX
        }
        recognizer.setTranslation(.zero, in: editContainerView)
    }
    
    @objc func handleLeftHandlerPan(_ recognizer: UIPanGestureRecognizer) {
        player.pause()
        let translation = recognizer.translation(in: editContainerView)
        let newX = leftHandleConstraint.constant + translation.x
        if newX >= TrackViewController.HANDLE_WIDTH && newX <= rightHandleConstraint.constant {
            leftHandleConstraint.constant = newX
        }
        recognizer.setTranslation(.zero, in: editContainerView)
    }
    
    
    // TODO: to enable reorder, maybe use UICollectionView instead of stacked view
    @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        let location = recognizer.location(in: trackView)
        // TODO: drop the clip to location it should be / maybe animate it
        if recognizer.state == .began {
            _selectedView = get_selectedView(in: location)
        }
        if recognizer.state == .changed {
            _selectedView?.center.x = location.x
        }
        if recognizer.state == .ended {

        }
    }
    
    private func updateCurrentPlayingItem() {
        let t = player.currentTime()
        for (idx, asset) in assets.enumerated() {
            if asset.trackTimeRange.containsTime(t) {
                if let item = trackView.subviews[idx] as? TrackItemView {
                    currentPlayingView = item
                    break
                }
            }
        }
    }
    
    private func updateEditViewProgress() {
        guard let selectedView = _selectedView else { return }
        let asset = assets[selectedView.index]
        let currentTime = player.currentTime()
        if asset.trackTimeRange.containsTime(currentTime) {
            let percentage = (currentTime - asset.trackTimeRange.start).seconds / asset.trackTimeRange.duration.seconds
            let sampleRange = selectedView.editView.zoomSamples
            let duration = Int(Double(sampleRange.upperBound - sampleRange.lowerBound) * percentage)
            selectedView.editView.highlightedSamples = sampleRange.lowerBound ..< sampleRange.lowerBound + duration
        } else if currentTime > asset.trackTimeRange.end {
            selectedView.editView.highlightedSamples = selectedView.editView.zoomSamples
        } else {
            selectedView.editView.highlightedSamples = nil
        }
    }
    
    func loadAsset(asset: AVAsset, assetRange: CMTimeRange) {
        let item = TrackItemView(asset: asset, size: CGSize(width: view.frame.width, height: view.frame.height / 2))
        widthConstraint.constant += itemWidth
        item.index = trackView.arrangedSubviews.count
        item.heightAnchor.constraint(equalToConstant: view.frame.height / 2).isActive = true
        trackView.addArrangedSubview(item)
        let trackTimeRange = assets.last != nil ? CMTimeRangeMake(start: assets.last!.trackTimeRange.end, duration: assetRange.duration) : assetRange
        assets.append(TrackAsset(asset: asset, assetTimeRange: assetRange, trackTimeRange: trackTimeRange))
    }
    
    func deleteSelected() -> CMTimeRange? {
        guard let selected = _selectedView else { return nil }
        let removed = assets.remove(at: selected.index)
        for i in selected.index..<assets.count {
            assets[i].trackSubtract(removed.trackTimeRange.duration)
        }
        widthConstraint.constant -= itemWidth
        for v in trackView.subviews {
            guard let v = v as? TrackItemView else { continue }
            if (v.index > selected.index) {
                selected.index -= 1
            }
        }
        selected.removeFromSuperview()
        if currentPlayingView?.index == selected.index {
            currentPlayingView = nil
        }
        _selectedView = nil
        return removed.trackTimeRange
    }
    
    // return track timerange that needs to be removed
    func trim() -> (CMTimeRange, CMTimeRange)? {
        guard let selected = _selectedView else { return nil }
        let left = (leftHandleConstraint.constant - TrackViewController.HANDLE_WIDTH) / (editContainerView.frame.width - TrackViewController.HANDLE_WIDTH * 2)
        let right = (rightHandleConstraint.constant - TrackViewController.HANDLE_WIDTH) / (editContainerView.frame.width - TrackViewController.HANDLE_WIDTH * 2)
        let asset = assets[selected.index]
        let duration = asset.assetTimeRange.duration
        let start = CMTimeMake(value: Int64(round(Double(duration.value) * left)), timescale: duration.timescale)
        let end = CMTimeMake(value: Int64(round(Double(duration.value) * right)), timescale: duration.timescale)
        // + assetTimeRange.start because it could be second, third ... edit on the same clip
        // the previous edit already changed the assetTimeRange, moving the start of assetTimeRange
        if let (leftRange, rightRange) = asset.trim(start: asset.assetTimeRange.start + start, end: asset.assetTimeRange.start + end) {
            selected.zoomSamples = calculateZoomSamples(asset: asset, totalSamples: selected.totalSamples)
            let subtract = leftRange.duration + rightRange.duration
            for i in selected.index+1 ..< assets.count {
                assets[i].trackSubtract(subtract)
            }
            _selectedView = nil
            return (leftRange, rightRange)
        }
        return nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        for observer in playerObservers {
            player.removeTimeObserver(observer)
        }
    }
}
