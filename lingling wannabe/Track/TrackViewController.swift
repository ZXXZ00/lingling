//
//  TrackViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/14/23.
//

import UIKit
import AVFoundation


class TrackViewController: UIViewController {
    
    private let player: AVPlayer
    var itemWidth: CGFloat = 40 {
        didSet {
            widthConstraint.constant = itemWidth * CGFloat(trackView.arrangedSubviews.count)
        }
    }
    
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
    private var selectedView: TrackItemView? = nil {
        didSet {
            oldValue?.backgroundColor = TrackViewController.DEFAULT_COLOR
            selectedView?.backgroundColor = .systemRed
            currentEditView = selectedView?.editView
        }
    }
    
    private var assets: [TrackAsset] = []
    
    static let HANDLE_WIDTH: CGFloat = 12
    
    static let DEFAULT_COLOR: UIColor = .gray

    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init(player: AVPlayer) {
        self.player = player
        widthConstraint = trackView.widthAnchor.constraint(equalToConstant: 0)
        leftHandleConstraint = leftHandleView.rightAnchor.constraint(equalTo: editContainerView.leftAnchor)
        rightHandleConstraint = rightHandleView.leftAnchor.constraint(equalTo: editContainerView.leftAnchor)
        super.init(nibName: nil, bundle: nil)
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
    
    @objc func handleTouch(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: trackView)
        selectedView = getSelectedView(in: location)
        guard let selectedView = selectedView else {
            return
        }
        let asset = assets[selectedView.index]
        let duration = asset.asset.duration.seconds
        let start = asset.assetTimeRange.start.seconds / duration
        let end = asset.assetTimeRange.end.seconds / duration
                
        let totalSamples = Double(selectedView.totalSamples)
        selectedView.editView.zoomSamples = Int(start*totalSamples) ..< Int(end*totalSamples)
        
        leftHandleConstraint.constant = TrackViewController.HANDLE_WIDTH
        rightHandleConstraint.constant = editContainerView.frame.width - TrackViewController.HANDLE_WIDTH
    }
    
    private func getSelectedView(in location: CGPoint) -> TrackItemView? {
        for subview in trackView.arrangedSubviews {
            if subview.frame.contains(location) {
                return subview as? TrackItemView
            }
        }
        return nil
    }
    
    @objc func handleRightHandlerPan(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: editContainerView)
        let newX = rightHandleConstraint.constant + translation.x
        if newX >= leftHandleConstraint.constant && newX <= editContainerView.frame.width - TrackViewController.HANDLE_WIDTH {
            rightHandleConstraint.constant = newX
        }
        recognizer.setTranslation(.zero, in: editContainerView)
    }
    
    @objc func handleLeftHandlerPan(_ recognizer: UIPanGestureRecognizer) {
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
            selectedView = getSelectedView(in: location)
        }
        if recognizer.state == .changed {
            selectedView?.center.x = location.x
        }
        if recognizer.state == .ended {

        }
    }
    
    func loadAsset(asset: AVAsset, assetRange: CMTimeRange) {
        let item = TrackItemView(asset: asset, size: CGSize(width: view.frame.width, height: view.frame.height / 2))
        widthConstraint.constant += itemWidth
        item.index = trackView.arrangedSubviews.count
        item.heightAnchor.constraint(equalToConstant: view.frame.height / 2).isActive = true
        trackView.addArrangedSubview(item)
        assets.append(TrackAsset(asset: asset, assetTimeRange: assetRange, trackTimeRange: assetRange))
    }
}
