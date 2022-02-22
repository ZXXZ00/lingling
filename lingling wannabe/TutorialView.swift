//
//  TutorialView.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 2/12/22.
//

import UIKit

class TutorialView: UIView {
    
    var parentView: UIView? = nil
    var nextView: UIView? = nil
    
    var interactive: CGRect
    
    let nextButton = UIButton()
    
    var completion: (() -> Void)? = nil
    
    init(frame: CGRect, holeRect: CGRect, fillColor: CGColor = UIColor(white: 0, alpha: 0.8).cgColor) {
        let background = UIBezierPath(rect: frame)
        let hole = UIBezierPath(roundedRect: holeRect, cornerRadius: 10)
        interactive = holeRect
        background.append(hole)
        background.usesEvenOddFillRule = true
        
        let fillLayer = CAShapeLayer()
        fillLayer.path = background.cgPath
        fillLayer.fillRule = .evenOdd
        fillLayer.fillColor = fillColor
        super.init(frame: frame)
        layer.addSublayer(fillLayer)
        
        nextButton.addTarget(self, action: #selector(nxt), for: .touchUpInside)
        addSubview(nextButton)
    }
    
    @objc func nxt() {
        if let p = parentView, let n = nextView {
            p.addSubview(n)
        }
        removeFromSuperview()
        if let f = completion {
            f()
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return interactive.contains(point) ? nil : view
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoder not supported!")
    }
}
