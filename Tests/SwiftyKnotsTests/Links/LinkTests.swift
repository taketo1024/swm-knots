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
    
    typealias A = LaurentPolynomial<𝐐>
    
    func testEmpty() {
        let e = Link.empty
        XCTAssertEqual(e.components.count, 0)
        XCTAssertEqual(e.crossingNumber, 0)
        XCTAssertEqual(e.unnormalizedJonesPolynomial, A(1))
    }

    func testUnknot() {
        let O = Link.unknot
        XCTAssertEqual(O.components.count, 1)
        XCTAssertEqual(O.crossingNumber, 0)
        XCTAssertEqual(O.JonesPolynomial, A(1))
    }

    func testHopfLink() {
        let O = Link.HopfLink
        XCTAssertEqual(O.components.count, 2)
        XCTAssertEqual(O.crossingNumber, 2)
        XCTAssertEqual(O.writhe, -2)
        XCTAssertEqual(O.JonesPolynomial, A(lowerDegree: -5, coeffs: [1, 0, 0, 0, 1]))
    }

    func testTrefoil() {
        let O = Link.trefoil
        XCTAssertEqual(O.components.count, 1)
        XCTAssertEqual(O.crossingNumber, 3)
        XCTAssertEqual(O.writhe, -3)
        XCTAssertEqual(O.JonesPolynomial, A(lowerDegree: -8, coeffs: [-1, 0, 1, 0, 0, 0, 1]))
    }
}
