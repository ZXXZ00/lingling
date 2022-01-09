//
//  CalendarCell.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/27/21.
//

import UIKit

class CalendarCell : UICollectionViewCell {
    
    let dayLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let scale = UserInfoViewController.scale
        backgroundColor = .white
        dayLabel.font = UIFont(name: "AmericanTypewriter", size: 10 * scale)
        dayLabel.textAlignment = .right
        dayLabel.bounds = CGRect(x: 0, y: 0, width: 14*scale, height: 7*scale)
        dayLabel.center = CGPoint(x: frame.width-8*scale, y: 5*scale)
        dayLabel.textColor = .black
        addSubview(dayLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    func clearAsset() {
        for subview in subviews {
            if subview.contentMode == .scaleAspectFit {
                subview.removeFromSuperview()
            }
        }
        //if layer.sublayers == nil { return }
        //layer.sublayers?.removeSubrange(1..<layer.sublayers!.count)
    }
    
    override func prepareForReuse() {
        clearAsset()
    }
    
    func addAsset(filenames: [String]) {
        var counter = 0
        let scale = UserInfoViewController.scale
        let assetScale = scale * 0.045
        // 300 is the standard size of cavnas
        var position = CGPoint(x: 300/2 * assetScale, y: 10 * scale + 300/2 * assetScale)
        for f in filenames {
            let asset = pdf(filename: f, scale: assetScale)
            asset.center = position
            addSubview(asset)
            if position.x + 300*assetScale < frame.width {
                position.x += 300*assetScale
            } else {
                position.x = 300/2 * assetScale
                position.y += 300*assetScale
            }
            counter += 1
            if counter == 12 { break }
        }
        if filenames.count - counter > 0 {
            // increment x position once again
            position.x += 300*assetScale
            // TODO: add ... asset to it
        }
    }
}
