//
//  LinkTests.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import XCTest
import SwiftyMath
@testable import SwiftyKnots

class JonesPolynomialTests: XCTestCase {
    
    typealias A = LaurentPolynomial<_q, 𝐙>
    
    override func setUp() {
        try! Link.loadTable("K10")
        try! Link.loadTable("L10")
    }
    
    override func tearDown() {
        Link.unloadTable()
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
        let L = Link.load("L2a1")!
        XCTAssertEqual(JonesPolynomial(L), A(coeffs: [-5: 1, -1: 1]) )
    }
    
    func testHopfLinkReversed() {
        let L = Link.load("L2a1")!.reversed
        XCTAssertEqual(JonesPolynomial(L), A(coeffs: [-5: 1, -1: 1]) )
    }
    
    func testHopfLinkMirrored() {
        let L = Link.load("L2a1")!.mirrored
        XCTAssertEqual(JonesPolynomial(L), A(coeffs: [5: 1, 1: 1]) )
    }
    
    func testTrefoil() {
        let K = Link.load("3_1")!
        XCTAssertEqual(JonesPolynomial(K), A(coeffs: [-8: -1, -6: 1, -2: 1]))
    }
    
    func testTrefoilReversed() {
        let K = Link.load("3_1")!.reversed
        XCTAssertEqual(JonesPolynomial(K), A(coeffs: [-8: -1, -6: 1, -2: 1]))
    }
    
    func testTrefoilMirrored() {
        let K = Link.load("3_1")!.mirrored
        XCTAssertEqual(JonesPolynomial(K), A(coeffs: [8: -1, 6: 1, 2: 1]))
    }
}
