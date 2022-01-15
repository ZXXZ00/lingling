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
        for _ in 0..<100 {
            let start = Int.random(in: 0..<2147483647)
            let duration = Int.random(in: 1..<10000)
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
        }
    }
    
    //func testAddRecord() throws {
    //    // this testcase suppose there is no authorization on the server side
    //    var start = 1640476710
    //    let token = CredentialManager.shared.getToken()
    //    for _ in 0..<5 {
    //        DataManager.shared.addRecord(username: "dddd", time: start, duration: 900, asset: "semiquaver", attributes: "{\"music\": \(0.8)}", token: token)
    //        sleep(10)
    //        let res = DataManager.shared.getRecord(username: "dddd", start: start-1, end: start+1)
    //        XCTAssertEqual(res[0].username, "dddd")
    //        XCTAssertEqual(res[0].time, Int64(start))
    //        XCTAssert(res[0].synced)
    //        start += 901
    //    }
    //    print("next start: \(start+1)")
    //}

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
