//
//  ResultDelegate.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 3/21/21.
//

import Foundation
import SoundAnalysis

class ResultDelegate {
    static let shared = ResultDelegate()
    
    private var time: [(Double, Double)] = []
    private var results: [[SNClassification]] = []
    
    private var tmp: [(Double, Double, Double)] = []
    
    func append(start: Double, end: Double, _ result: [SNClassification]) {
        //time.append((start, end))
        //results.append(result)
        if result[0].identifier == "background" {
            tmp.append((start, result[1].confidence, result[0].confidence))
        } else {
            tmp.append((start, result[0].confidence, result[1].confidence))
        }
    }
    
    @objc func print_() {
        //print(time)
        //print(results)
        for t in tmp {
            print(t.0, t.1, t.2, separator: ",")
        }
    }
}

