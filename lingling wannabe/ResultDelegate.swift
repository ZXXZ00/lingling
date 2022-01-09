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
    
    var debugP = 0.0
    
    var isPracticing = false
    private var musicCounter = 0
    private var backgroundCounter = 0
    
    private var res: [(start: Double, end: Double, music: Double, background: Double)] = []
    
    private init() { }
    
    func append(start: Double, end: Double, _ result: [SNClassification]) {
        let musicP: Double
        if result[0].identifier == "background" {
            res.append((start, end, result[1].confidence, result[0].confidence))
            musicP = result[1].confidence
        } else {
            res.append((start, end, result[0].confidence, result[1].confidence))
            musicP = result[0].confidence
        }
        if musicP > ResultDelegate.cutoff {
            musicCounter += 1
        } else {
            backgroundCounter += 1
        }
        debugP = musicP
        if musicCounter > 2 {
            musicCounter = 0
            backgroundCounter = 0
            isPracticing = true
        }
        if backgroundCounter > 20 {
            musicCounter = 0
            backgroundCounter = 0
            isPracticing = false
        }
    }
    
    func musicPercentage(cutoff: Double) -> Double {
        var total = 0.0
        var music = 0.0
        for i in 1..<res.count {
            if res[i].music > cutoff {
                music += res[i].start - res[i-1].start
            }
            total += res[i].start - res[i-1].start
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
            if res[0].music > cutoffs[i] {
                startend[i] += res[0].end - res[0].start
            }
        }
        startendTotal += res[0].end - res[0].start
        for i in 1..<res.count {
            let dstart = res[i].start - res[i-1].start
            let dend = res[i].end - res[i-1].end
            let dstartend = res[i].end - res[i].start
            for j in 0..<cutoffs.count {
                if res[i].music > cutoffs[j] {
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
        res.removeAll()
    }
    
    @objc func print_() {
        for t in res {
            print(t.0, t.1, t.2, t.3, separator: ",")
        }
    }
}

