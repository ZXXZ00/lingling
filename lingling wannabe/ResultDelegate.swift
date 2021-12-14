//
//  ResultDelegate.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 3/21/21.
//

import Foundation
import SoundAnalysis
import SQLite

class ResultDelegate {
    static let shared = ResultDelegate()
    static var cutoff = 0.5
    static var percentage = 0.5
    
    private var tmp: [(start: Double, end: Double, music: Double, background: Double)] = []
    
    func append(start: Double, end: Double, _ result: [SNClassification]) {
        //time.append((start, end))
        //results.append(result)
        if result[0].identifier == "background" {
            tmp.append((start, end, result[1].confidence, result[0].confidence))
        } else {
            tmp.append((start, end, result[0].confidence, result[1].confidence))
        }
        //time.append((start, end))
        
    }
    
    func musicPercentage(cutoff: Double) -> Double {
        var total = 0.0
        var music = 0.0
        for i in 1..<tmp.count {
            if tmp[i].music > cutoff {
                music += tmp[i].start - tmp[i-1].start
            }
            total += tmp[i].start - tmp[i-1].start
        }
        return music/total
    }
    
    func test() -> [[Double]] {
        let cutoffs = [0.5,0.55,0.6,0.65,0.7,0.75,0.8,0.85]
        var start = Array(repeating: 0.0, count: cutoffs.count)
        var startTotal = 0.0
        var end = Array(repeating: 0.0, count: cutoffs.count)
        var endTotal = 0.0
        var startend = Array(repeating: 0.0, count: cutoffs.count)
        var startendTotal = 0.0
        var ret: [[Double]] = [[],[],[]]
        for i in 0..<cutoffs.count {
            if tmp[0].music > cutoffs[i] {
                startend[i] += tmp[0].end - tmp[0].start
            }
        }
        startendTotal += tmp[0].end - tmp[0].start
        for i in 1..<tmp.count {
            let dstart = tmp[i].start - tmp[i-1].start
            let dend = tmp[i].end - tmp[i-1].end
            let dstartend = tmp[i].end - tmp[i].start
            for j in 0..<cutoffs.count {
                if tmp[i].music > cutoffs[j] {
                    start[j] += dstart
                    end[j] += dend
                    startend[j] += dstartend
                }
            }
            startTotal += dstart
            endTotal += dend
            startendTotal += dstartend
        }
        for i in 0..<cutoffs.count {
            ret[0].append(start[i]/startTotal)
            ret[1].append(end[i]/endTotal)
            ret[2].append(startend[i]/startendTotal)
        }
        return ret
    }
    
    func reset() {
        tmp.removeAll()
    }
    
    @objc func print_() {
        for t in tmp {
            print(t.0, t.1, t.2, t.3, separator: ",")
        }
    }
}

