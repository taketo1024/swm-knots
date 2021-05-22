//
//  LinkTests.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import XCTest
import SwiftyMath
@testable import SwiftyKnots

class LinkTests: XCTestCase {
    
    override func setUp() {
        try! Link.loadResource("K10")
        try! Link.loadResource("L10")
    }
    
    override func tearDown() {
        Link.unloadResources()
    }
    
    func testEmpty() {
        let e = Link.empty
        XCTAssertEqual(e.components.count, 0)
        XCTAssertEqual(e.crossingNumber, 0)
    }

    func testUnknot() {
        let O = Link.unknot
        XCTAssertEqual(O.components.count, 1)
        XCTAssertEqual(O.crossingNumber, 0)
    }

    func testHopfLink() {
        let L = try! Link.load("L2a1")
        XCTAssertEqual(L.components.count, 2)
        XCTAssertEqual(L.crossingNumber, 2)
        XCTAssertEqual(L.writhe, -2)
    }
    
    func testHopfLinkReversed() {
        let L = try! Link.load("L2a1").reversed
        XCTAssertEqual(L.components.count, 2)
        XCTAssertEqual(L.crossingNumber, 2)
        XCTAssertEqual(L.writhe, -2)
    }
    
    func testHopfLinkMirrored() {
        let L = try! Link.load("L2a1").mirrored
        XCTAssertEqual(L.components.count, 2)
        XCTAssertEqual(L.crossingNumber, 2)
        XCTAssertEqual(L.writhe, 2)
    }
    
    func testTrefoil() {
        let K = try! Link.load("3_1")
        XCTAssertEqual(K.components.count, 1)
        XCTAssertEqual(K.crossingNumber, 3)
        XCTAssertEqual(K.writhe, -3)
    }
    
    func testTrefoilReversed() {
        let K = try! Link.load("3_1").reversed
        XCTAssertEqual(K.components.count, 1)
        XCTAssertEqual(K.crossingNumber, 3)
        XCTAssertEqual(K.writhe, -3)
    }
    
    func testTrefoilMirrored() {
        let K = try! Link.load("3_1").mirrored
        XCTAssertEqual(K.components.count, 1)
        XCTAssertEqual(K.crossingNumber, 3)
        XCTAssertEqual(K.writhe, 3)
    }
}
