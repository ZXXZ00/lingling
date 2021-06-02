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
        if layer.sublayers == nil { return }
        layer.sublayers?.removeSubrange(1..<layer.sublayers!.count)
    }
    
    func addAsset(filenames: [String]) {
        let scale = UserInfoViewController.scale
        let assetScale = scale * 0.045
        // 300 is the standard size of cavnas
        var position = CGPoint(x: 300 * assetScale, y: 10 * scale + 300 * assetScale)
        for f in filenames {
            if let url = Bundle.main.url(forResource: f, withExtension: "svg") {
                let asset = svg(at: url, scale: assetScale)
                asset.bounds = CGRect(x: 0, y: 0, width: 300, height: 300)
                asset.anchorPoint = CGPoint(x: 1, y: 1)
                asset.position = position
                if position.x + 300*assetScale < frame.width {
                    position.x += 300*assetScale
                } else {
                    position.x = 300 * assetScale
                    position.y += 300*assetScale
                }
                layer.addSublayer(asset)
            } else {
                // for the future it not on device we may retrieve from cloud
            }
        }
    }
}
