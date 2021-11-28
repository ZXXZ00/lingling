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
    var noteView = UIImageView()
    let noteScale: CGFloat
    let buttonScale: CGFloat
    weak var controller: UIViewController?
    let start: UIButton
    let username: UIButton
    let leaderboard: UIButton
    
    
    let question: UIImageView
    let rect: CAShapeLayer
    var reward = UIImageView()
    var rewardPath = CALayer()
    var isShowingResult = false
    var touchCount = 0
    
    let text = UITextView()
    
    
    public convenience init(frame: CGRect, user: String, controller: UIViewController) {
        self.init(frame: frame)
        self.controller = controller
        username.setTitle(user, for: .normal)
    }
    
    public override init(frame: CGRect) {
        slider = MSCircularSlider(frame: CGRect(x: 0, y: 0, width: frame.width*0.7, height: frame.width*0.7))
        noteScale = frame.width/300 * 0.4 // 300 is the size of note
        buttonScale = min(frame.width/350, 1.5)
        start = UIButton(frame: CGRect(x: 0, y: 0, width: 103.5*buttonScale, height: 64*buttonScale))
        username = UIButton(frame: CGRect(x: 0, y: 0, width: frame.width/2, height: 20*buttonScale))
        leaderboard = UIButton(frame: CGRect(x: frame.width - 60*buttonScale, y: -16*buttonScale, width: 60*buttonScale, height: 60*buttonScale))
        rect = CAShapeLayer()
        rect.path = UIBezierPath(rect: frame).cgPath
        rect.fillColor = UIColor(white: 1, alpha: 1).cgColor
        question = pdf(filename: "question", scale: noteScale*2)
        super.init(frame: frame)
        setUp()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        username.center.y += safeAreaInsets.top
        leaderboard.center.y += safeAreaInsets.top
    }
    
    private func setUp() {
        backgroundColor = .white
        slider.filledColor = .black
        slider.center = self.center
        slider.lineWidth = 2
        slider.maximumAngle = 270
        slider.delegate = self
        addSubview(slider)
        
        start.layer.borderWidth = 1 * buttonScale
        start.layer.cornerRadius = 10
        start.setImage(UIImage(named: "start.pdf"), for: .normal)
        start.imageView?.contentMode = .scaleAspectFit
        start.imageEdgeInsets.top = 10*buttonScale
        start.imageEdgeInsets.bottom = 10*buttonScale
        start.imageEdgeInsets.left = -66*buttonScale
        start.setTitle("15:00", for: .normal)
        start.titleLabel?.font = UIFont(name: "AmericanTypewriter", size: 20*buttonScale)
        start.setTitleColor(.black, for: .normal)
        start.titleEdgeInsets.left = -140*buttonScale
        start.center = CGPoint(x: self.center.x, y: self.center.y + slider.frame.height/1.5)
        start.addTarget(controller, action: #selector(MainViewController.startAnalyze), for: .touchUpInside)
        addSubview(start)
        
        loadNote(filename: "semiquaver")
        
        username.contentHorizontalAlignment = .left
        username.titleLabel?.font = UIFont(name: "AmericanTypewriter", size: 16*buttonScale)
        username.setTitleColor(.black, for: .normal)
        username.addTarget(controller, action: #selector(MainViewController.showUserInfo), for: .touchUpInside)
        addSubview(username)
        
        leaderboard.contentMode = .scaleAspectFit
        leaderboard.setImage(UIImage(named: "leaderboard.pdf"), for: .normal)
        leaderboard.addTarget(controller, action: #selector(MainViewController.showLeaderBoard), for: .touchUpInside)
        addSubview(leaderboard)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(touchHandler))
        addGestureRecognizer(tap)
    }
    
    private func loadNote(filename: String) {
        if (currSymbol == filename) { return }
        noteView.removeFromSuperview()
        noteView = pdf(filename: filename, scale: noteScale)
        // 300 is the size of notation canvas
        noteView.center = self.center
        addSubview(noteView)
        currSymbol = filename
    }
    
    func showResult() {
        start.alpha = 0
        
        self.layer.addSublayer(rect)
        isShowingResult = true
        touchCount = 0
        question.center = self.center
        addSubview(question)
        
        let res = ResultDelegate.shared.test()
        text.frame = CGRect(x: 40, y: 40, width: 250, height: 400)
        var tmp = ""
        for arr in res {
            for per in arr {
                tmp += String(per) + ","
            }
            tmp += "\n\n "
        }
        text.isEditable = false
        text.backgroundColor = .clear
        text.textColor = .black
        text.text = tmp
        //self.addSubview(text)
    }
    
    func reveal() {
        question.removeFromSuperview()
        let duration: Double = 10
        if ResultDelegate.shared.musicPercentage(cutoff: ResultDelegate.cutoff) > ResultDelegate.percentage {
            reward = pdf(filename: currSymbol, scale: noteScale*2)
            rewardPath = drawAnimate(name: currSymbol, duration: duration)
        } else {
            reward = pdf(filename: currSymbol+"_rest", scale: noteScale*2)
            rewardPath = drawAnimate(name: currSymbol+"_rest", duration: duration)
        }
        rewardPath.transform = CATransform3DMakeScale(noteScale*2, noteScale*2, 1)
        rewardPath.bounds = CGRect(x: 0, y: 0, width: 300, height: 300)
        reward.center = self.center
        rewardPath.position = self.center
        
        self.layer.addSublayer(rewardPath)
        reward.alpha = 0
        addSubview(reward)
        UIView.animate(withDuration: 1, delay: duration, animations: {
            self.reward.alpha = 1
        }, completion: { finished in
            self.touchCount += 1
        })
    }
    
    func dismissResult() {
        touchCount = 0
        rect.removeFromSuperlayer()
        rewardPath.removeFromSuperlayer()
        start.alpha = 1
        isShowingResult = false
        text.removeFromSuperview()
        let path = UIBezierPath()
        path.move(to: self.center)
        path.addLine(to: CGPoint(x: 40, y: 40)) // 40 magic
        let animation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.position))
        animation.duration = 1
        animation.repeatCount = 1
        animation.path = path.cgPath
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        reward.layer.add(animation, forKey: nil)
        UIView.animate(withDuration: 1, delay: 0, animations: {
            self.reward.transform = CGAffineTransform(scaleX: 0.05, y: 0.05)
        }, completion: { finished in
            self.reward.removeFromSuperview()
        })
    }
    
    @objc func touchHandler() {
        print(isShowingResult, touchCount)
        if isShowingResult {
            touchCount += 1
            if touchCount == 1 {
                reveal()
            } else if touchCount == 2 {
                rewardPath.removeAllAnimations()
                rewardPath.removeFromSuperlayer()
                //if let sublayers = rewardPath.sublayers {
                //    for sublayer in sublayers {
                //        sublayer.removeAllAnimations()
                //    }
                //}
                reward.layer.removeAllAnimations()
                reward.alpha = 1
            } else {
                dismissResult()
            }
        }
    }
    
    // 15, 30, 60, 120, 240 minutes are the interval corresponding to
    // semiquaver, quaver, crotchet, half, whole
    // the value for circular slider ranges from 0 to 100
    // each inteval has equal spacing on the slider
    func circularSlider(_ slider: MSCircularSlider, valueChangedTo value: Double, fromUser: Bool) {
        if (value < 20) {
            minutes = 15
            loadNote(filename: "semiquaver")
            start.setTitle("15:00", for: .normal)
        } else if (value < 40) {
            minutes = 30
            loadNote(filename: "quaver")
            start.setTitle("30:00", for: .normal)
        } else if (value < 60) {
            minutes = 60
            loadNote(filename: "crotchet")
            start.setTitle("60:00", for: .normal)
        } else if (value < 80) {
            minutes = 120
            loadNote(filename: "half")
            start.setTitle("120:00", for: .normal)
        } else {
            minutes = 240
            loadNote(filename: "whole")
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
