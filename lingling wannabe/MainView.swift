//
//  MainView.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 3/28/21.
//

import UIKit

class MainView: UIView, MSCircularSliderDelegate {
    
    let slider: MSCircularSlider
    
    public override init(frame: CGRect) {
        slider = MSCircularSlider(frame: CGRect(x: 0, y: 0, width: frame.width*0.7, height: frame.width*0.7))
        super.init(frame: frame)
        setUp()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    private func setUp() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .white
        slider.maximumAngle = 270
        self.addSubview(slider)
        slider.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        slider.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        //frame: CGRect(x: 0, y: 0, width: 400, height: 400)
    }
    
    func circularSlider(_ slider: MSCircularSlider, valueChangedTo value: Double, fromUser: Bool) {
        
    }
    
    func circularSlider(_ slider: MSCircularSlider, startedTrackingWith value: Double) {
        
    }
    
    func circularSlider(_ slider: MSCircularSlider, endedTrackingWith value: Double) {
        
    }
    
    func circularSlider(_ slider: MSCircularSlider, directionChangedTo value: MSCircularSliderDirection) {
        
    }
    
    func circularSlider(_ slider: MSCircularSlider, revolutionsChangedTo value: Int) {
        
    }
}
