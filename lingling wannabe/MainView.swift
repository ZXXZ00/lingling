//
//  MainView.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 3/28/21.
//

import UIKit
import PocketSVG

class MainView: UIView, MSCircularSliderDelegate {
    
    let slider: MSCircularSlider
    var currSymbol = "null"
    var minutes : Double = 15
    var noteLayer = CALayer()
    let noteScale: CGFloat
    let buttonScale: CGFloat
    weak var controller: UIViewController?
    let start: UIButton
    let username: UIButton
    
    public convenience init(frame: CGRect, controller: UIViewController) {
        self.init(frame: frame)
        self.controller = controller
    }
    
    public override init(frame: CGRect) {
        slider = MSCircularSlider(frame: CGRect(x: 0, y: 0, width: frame.width*0.7, height: frame.width*0.7))
        noteScale = frame.width/300 * 0.4 // 300 is the size of note
        buttonScale = min(frame.width/400, 1.5)
        start = UIButton(frame: CGRect(x: 0, y: 0, width: 103.5*buttonScale, height: 64*buttonScale))
        username = UIButton(frame: CGRect(x: 0, y: 0, width: frame.width/2, height: 20*buttonScale))
        super.init(frame: frame)
        setUp()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        username.center.y += safeAreaInsets.top
    }
    
    private func setUp() {
        backgroundColor = .white
        slider.filledColor = .black
        slider.center = self.center
        slider.lineWidth = 1
        slider.maximumAngle = 270
        slider.delegate = self
        addSubview(slider)
        
        //start.backgroundColor = UIColor(white: 0.97, alpha: 1)
        start.layer.borderWidth = 0.6 * buttonScale
        start.layer.cornerRadius = 10
        start.setImage(UIImage(named: "start.pdf"), for: .normal)
        start.imageView?.contentMode = .scaleAspectFit
        start.imageEdgeInsets.top = 10*buttonScale
        start.imageEdgeInsets.bottom = 10*buttonScale
        start.imageEdgeInsets.left = -66*buttonScale
        start.setTitle("15:00", for: .normal)
        start.titleLabel?.font = UIFont(name: "AmericanTypewriter-Light", size: 20*buttonScale)
        start.setTitleColor(.black, for: .normal)
        start.titleEdgeInsets.left = -136*buttonScale
        start.center = CGPoint(x: self.center.x, y: self.center.y + slider.frame.height/1.5)
        start.addTarget(controller, action: #selector(MainViewController.startAnalyze), for: .touchUpInside)
        addSubview(start)
        
        loadSVG(filename: "semiquaver")
        
        username.titleLabel?.font = UIFont(name: "AmericanTypewriter", size: 16*buttonScale)
        username.setTitleColor(.black, for: .normal)
        username.setTitle("abcdefjhijklmnopqrstuvwxyz0123456789", for: .normal)
        username.addTarget(controller, action: #selector(MainViewController.showUserInfo), for: .touchUpInside)
        addSubview(username)
    }
    
    private func loadSVG(filename: String) {
        if (currSymbol == filename) { return }
        noteLayer.removeFromSuperlayer()
        let url = Bundle.main.url(forResource: filename, withExtension: "svg")!
        noteLayer = svg(at: url, scale: noteScale)
        noteLayer.bounds = CGRect(x: 0, y: 0, width: 300, height: 300)
        // 300 is the size of notation canvas
        noteLayer.position = self.center
        self.layer.addSublayer(noteLayer)
        currSymbol = filename
    }
    
    // 15, 30, 60, 120, 240 minutes are the interval corresponding to
    // semiquaver, quaver, crotchet, half, whole
    // the value for circular slider ranges from 0 to 100
    // each inteval has equal spacing on the slider
    func circularSlider(_ slider: MSCircularSlider, valueChangedTo value: Double, fromUser: Bool) {
        if (value < 20) {
            minutes = 15
            loadSVG(filename: "semiquaver")
            start.setTitle("15:00", for: .normal)
        } else if (value < 40) {
            minutes = 30
            loadSVG(filename: "quaver")
            start.setTitle("30:00", for: .normal)
        } else if (value < 60) {
            minutes = 60
            loadSVG(filename: "crotchet")
            start.setTitle("60:00", for: .normal)
        } else if (value < 80) {
            minutes = 120
            loadSVG(filename: "half")
            start.setTitle("120:00", for: .normal)
        } else {
            minutes = 240
            loadSVG(filename: "whole")
            start.setTitle("240:00", for: .normal)
        }
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
