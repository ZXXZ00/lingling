//
//  lingling_wannabeTests.swift
//  lingling wannabeTests
//
//  Created by Adam Zhao on 1/24/21.
//

import XCTest
@testable import lingling_wannabe

class lingling_wannabeTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCheckSum() throws {
        for _ in 0..<10000 {
            let start = Int.random(in: 0..<2147483647)
            let duration = Int.random(in: -10000..<10000)
            let checksum = computeCheckSum(start: start, duration: duration)
            let entropy1 = Int.random(in: 1..<827349507)
            let entropy2 = Int.random(in: 1..<238478734)
            let wrong = computeCheckSum(start: start+entropy1, duration: duration+entropy2)
            XCTAssert(verifyCheckSum(start: start, duration: duration, checksum: checksum))
            XCTAssert(verifyCheckSum(start: start+entropy1, duration: duration+entropy2, checksum: wrong))
            XCTAssert(!verifyCheckSum(start: start, duration: duration, checksum: wrong))
            XCTAssert(!verifyCheckSum(start: start+entropy1, duration: duration+entropy2, checksum: checksum))
            XCTAssert(!verifyCheckSum(start: start+entropy1, duration: duration, checksum: checksum))
            XCTAssert(!verifyCheckSum(start: start, duration: duration+entropy2, checksum: checksum))
            //print("[", start, ",", duration+entropy2, ",", "\""+checksum+"\"", "],")
        }
    }
    
    func testAddRecord() throws {
        var start = 1648422000
        DataManager.shared.clear()
        for _ in 0..<1 {
            DataManager.shared.addRecord(username: "iPad", time: start, duration: 900, asset: "semiquaver", attributes: nil, upload: false)
            start += 1
        }
        //sleep(5)
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let token = CredentialManager.shared.getToken()
        DataManager.shared.uploadUnsynced(username: "test", token: token)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            FilesManager.shared.convert2FLAC()
        }
    }

}
