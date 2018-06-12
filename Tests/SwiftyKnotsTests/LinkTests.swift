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
        let L = Link.HopfLink
        XCTAssertEqual(L.components.count, 2)
        XCTAssertEqual(L.crossingNumber, 2)
        XCTAssertEqual(L.writhe, -2)
    }
    
    func testHopfLinkReversed() {
        let L = Link.HopfLink.reversed
        XCTAssertEqual(L.components.count, 2)
        XCTAssertEqual(L.crossingNumber, 2)
        XCTAssertEqual(L.writhe, -2)
    }
    
    func testHopfLinkMirrored() {
        let L = Link.HopfLink.mirrored
        XCTAssertEqual(L.components.count, 2)
        XCTAssertEqual(L.crossingNumber, 2)
        XCTAssertEqual(L.writhe, 2)
    }
    
    func testTrefoil() {
        let K = Link.trefoil
        XCTAssertEqual(K.components.count, 1)
        XCTAssertEqual(K.crossingNumber, 3)
        XCTAssertEqual(K.writhe, -3)
    }
    
    func testTrefoilReversed() {
        let K = Link.trefoil.reversed
        XCTAssertEqual(K.components.count, 1)
        XCTAssertEqual(K.crossingNumber, 3)
        XCTAssertEqual(K.writhe, -3)
    }
    
    func testTrefoilMirrored() {
        let K = Link.trefoil.mirrored
        XCTAssertEqual(K.components.count, 1)
        XCTAssertEqual(K.crossingNumber, 3)
        XCTAssertEqual(K.writhe, 3)
    }
}
