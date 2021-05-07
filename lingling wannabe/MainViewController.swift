//
//  ViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 1/24/21.
//

import UIKit
import PocketSVG

class MainViewController: UIViewController {
    
    override func loadView() {
        let mainView = MainView(frame: UIScreen.main.bounds, controller: self)
        mainView.backgroundColor = .white
        self.view = mainView
    }
    
    override func viewDidLoad() {
        //super.viewDidLoad()
        //self.view.backgroundColor = .white
        //let mainView = MainView(frame: view.frame, controller: self)
        //view.addSubview(mainView)
        //mainView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        //mainView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        //loadTestView()
        
        // TODO: Add intro animation and dismiss it after a delay
    }

    func loadTestView() {
        let start = UIButton(type: .system)
        start.setTitle("start", for: .normal)
        start.addTarget(AudioStreamAnalyzer.shared, action: #selector(AudioStreamAnalyzer.analyze), for: .touchUpInside)
        start.frame = CGRect(x:view.center.x, y:view.center.y-50, width:100, height: 50)
        let stop = UIButton(type: .system)
        stop.setTitle("stop", for: .normal)
        stop.addTarget(AudioStreamAnalyzer.shared, action: #selector(AudioStreamAnalyzer.stop), for: .touchUpInside)
        stop.frame = CGRect(x:view.center.x, y: view.center.y+50, width: 100, height: 50)
        let test = UIButton(type: .system)
        test.setTitle("print", for: .normal)
        test.addTarget(ResultDelegate.shared, action: #selector(ResultDelegate.print_), for: .touchUpInside)
        test.frame = CGRect(x: view.center.x, y: view.center.y, width: 100, height: 50)
        test.center = view.center
        view.addSubview(start)
        view.addSubview(stop)
        view.addSubview(test)
    }
    
    @objc func startAnalyze() {
        var delay : Double = 15*60
        if let mainView = view as? MainView {
            delay = mainView.minutes * 60
        } else {
            return
        }
        let analyzeView = AnalyzeViewController()
        analyzeView.modalPresentationStyle = .fullScreen
        present(analyzeView, animated: true, completion: {
            AudioStreamAnalyzer.shared.analyze()
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                AudioStreamAnalyzer.shared.stop()
                self.dismiss(animated: true, completion: nil)
                ResultDelegate.shared.print_()
            }
        })
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

}

