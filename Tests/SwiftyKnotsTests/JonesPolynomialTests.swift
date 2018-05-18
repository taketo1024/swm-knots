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
    
    typealias A = JonesPolynomial
    
    func testEmpty() {
        let e = Link.empty
        XCTAssertEqual(e.JonesPolynomial(normalized: false), A(1))
    }

    func testUnknot() {
        let O = Link.unknot
        XCTAssertEqual(O.JonesPolynomial, A(1))
    }

    func testHopfLink() {
        let L = Link.HopfLink
        XCTAssertEqual(L.JonesPolynomial, A(coeffs: [-5: 1, -1: 1]) )
    }
    
    func testHopfLinkReversed() {
        let L = Link.HopfLink.reversed
        XCTAssertEqual(L.JonesPolynomial, A(coeffs: [-5: 1, -1: 1]) )
    }
    
    func testHopfLinkMirrored() {
        let L = Link.HopfLink.mirrored
        XCTAssertEqual(L.JonesPolynomial, A(coeffs: [5: 1, 1: 1]) )
    }
    
    func testTrefoil() {
        let K = Link.trefoil
        XCTAssertEqual(K.JonesPolynomial, A(coeffs: [-8: -1, -6: 1, -2: 1]))
    }
    
    func testTrefoilReversed() {
        let K = Link.trefoil.reversed
        XCTAssertEqual(K.JonesPolynomial, A(coeffs: [-8: -1, -6: 1, -2: 1]))
    }
    
    func testTrefoilMirrored() {
        let K = Link.trefoil.mirrored
        XCTAssertEqual(K.JonesPolynomial, A(coeffs: [8: -1, 6: 1, 2: 1]))
    }
}
