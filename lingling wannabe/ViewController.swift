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
        self.view.backgroundColor = .black
        let start = UIButton(type: .system)
        start.setTitle("start", for: .normal)
        start.addTarget(AudioStreamAnalyzer.shared, action: #selector(AudioStreamAnalyzer.analyze), for: .touchUpInside)
        start.frame = CGRect(x:20, y:20, width:100, height: 50)
        let stop = UIButton(type: .system)
        stop.setTitle("stop", for: .normal)
        stop.addTarget(AudioStreamAnalyzer.shared, action: #selector(AudioStreamAnalyzer.stop), for: .touchUpInside)
        stop.frame = CGRect(x:20, y: 100, width: 100, height: 50)
        let test = UIButton(frame: CGRect(x: 20, y: 200, width: 100, height: 50))
        test.setTitle("print", for: .normal)
        test.addTarget(ResultDelegate.shared, action: #selector(ResultDelegate.print_), for: .touchUpInside)
        test.setTitleColor(.systemBlue, for: .normal)
        self.view.addSubview(start)
        self.view.addSubview(stop)
        self.view.addSubview(test)
    }


}

