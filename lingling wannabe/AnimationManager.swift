//
//  AnimationManager.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 11/27/21.
//

import UIKit

class AnimationManager {
    static let shared = AnimationManager()
    
    private var animations: [CAAnimation]
    private var layers: [CALayer]
    
    private init() {
        animations = []
        layers = []
        //NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: NSNotification.Name., object: nil)
    }
    
    @objc func willResignActive() {
        for animation in animations {
            animation.speed = 0.0
        }
    }
    
    @objc func didBecomeActive() {
        
    }
}
