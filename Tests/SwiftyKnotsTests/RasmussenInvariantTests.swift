//
//  RasmussenInvariantTests.swift
//  SwiftyKnotsTests
//
//  Created by Taketo Sano on 2019/06/05.
//

import XCTest
import SwiftyKnots

class RasmussenInvariantTests: XCTestCase {

    func testUnknot() {
        let K = Link.unknot
        XCTAssertEqual(K.RasmussenInvariant, 0)
    }
    
    func testUnknot_RM1() {
        let K = Link(planarCode: [1,2,2,1])
        XCTAssertEqual(K.RasmussenInvariant, 0)
    }
    
    func testUnknot_RM2() {
        let K = Link(planarCode: [1,4,2,1], [2,4,3,3])
        XCTAssertEqual(K.RasmussenInvariant, 0)
    }
    
    func test3_1_Z() {
        let K = Knot(3, 1)
        XCTAssertEqual(K.RasmussenInvariant, -2)
    }
    
    func test4_1_Z() {
        let K = Knot(4, 1)
        XCTAssertEqual(K.RasmussenInvariant, 0)
    }
    
    func test5_1_Z() {
        let K = Knot(5, 1)
        XCTAssertEqual(K.RasmussenInvariant, -4)
    }
}
