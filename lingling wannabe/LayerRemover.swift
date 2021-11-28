//
//  LayerRemover.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 11/27/21.
//

import UIKit

class LayerRemover: NSObject, CAAnimationDelegate {
    
    private let layer: CALayer
    
    init(layer: CALayer) {
        self.layer = layer
        super.init()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        layer.removeFromSuperlayer()
    }
    
}
