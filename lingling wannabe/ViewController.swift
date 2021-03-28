//
//  ViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 1/24/21.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        loadTestView()
        let mainView = MainView(frame: view.frame)
        view.addSubview(mainView)
        mainView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        mainView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    func loadMainView() {
        
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
        view.addSubview(start)
        view.addSubview(stop)
        view.addSubview(test)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

}

