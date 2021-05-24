//
//  LinkTests.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import XCTest
import SwmCore
@testable import SwmKnots

class JonesPolynomialTests: XCTestCase {
    
    typealias A = LaurentPolynomial<𝐙, _q>
    
    override func setUp() {
        try! Link.loadResource("K10")
        try! Link.loadResource("L10")
    }
    
    override func tearDown() {
        Link.unloadResources()
    }
    
    func testEmpty() {
        let e = Link.empty
        XCTAssertEqual(JonesPolynomial(e, normalized: false), A(1))
    }

    func testUnknot() {
        let O = Link.unknot
        XCTAssertEqual(JonesPolynomial(O), A(1))
    }

    func testHopfLink() {
        let L = try! Link.load("L2a1")
        XCTAssertEqual(JonesPolynomial(L), [-5: 1, -1: 1] )
    }
    
    func testHopfLinkReversed() {
        let L = try! Link.load("L2a1").reversed
        XCTAssertEqual(JonesPolynomial(L), [-5: 1, -1: 1] )
    }
    
    func testHopfLinkMirrored() {
        let L = try! Link.load("L2a1").mirrored
        XCTAssertEqual(JonesPolynomial(L), [5: 1, 1: 1] )
    }
    
    func testTrefoil() {
        let K = try! Link.load("3_1")
        XCTAssertEqual(JonesPolynomial(K), [-8: -1, -6: 1, -2: 1])
    }
    
    func testTrefoilReversed() {
        let K = try! Link.load("3_1").reversed
        XCTAssertEqual(JonesPolynomial(K), [-8: -1, -6: 1, -2: 1])
    }
    
    func testTrefoilMirrored() {
        let K = try! Link.load("3_1").mirrored
        XCTAssertEqual(JonesPolynomial(K), [8: -1, 6: 1, 2: 1])
    }
}
