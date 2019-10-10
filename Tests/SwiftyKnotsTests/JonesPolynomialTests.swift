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
    
    func testEmpty() {
        let e = Link.empty
        XCTAssertEqual(JonesPolynomial(e, normalized: false), A(1))
    }

    func testUnknot() {
        let O = Link.unknot
        XCTAssertEqual(JonesPolynomial(O), A(1))
    }

    func testHopfLink() {
        let L = Link.HopfLink
        XCTAssertEqual(JonesPolynomial(L), A(coeffs: [-5: 1, -1: 1]) )
    }
    
    func testHopfLinkReversed() {
        let L = Link.HopfLink.reversed
        XCTAssertEqual(JonesPolynomial(L), A(coeffs: [-5: 1, -1: 1]) )
    }
    
    func testHopfLinkMirrored() {
        let L = Link.HopfLink.mirrored
        XCTAssertEqual(JonesPolynomial(L), A(coeffs: [5: 1, 1: 1]) )
    }
    
    func testTrefoil() {
        let K = Link.trefoil
        XCTAssertEqual(JonesPolynomial(K), A(coeffs: [-8: -1, -6: 1, -2: 1]))
    }
    
    func testTrefoilReversed() {
        let K = Link.trefoil.reversed
        XCTAssertEqual(JonesPolynomial(K), A(coeffs: [-8: -1, -6: 1, -2: 1]))
    }
    
    func testTrefoilMirrored() {
        let K = Link.trefoil.mirrored
        XCTAssertEqual(JonesPolynomial(K), A(coeffs: [8: -1, 6: 1, 2: 1]))
    }
}
