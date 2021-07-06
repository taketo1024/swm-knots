//
//  BraidTests.swift
//  SwiftyKnotsTests
//
//  Created by Taketo Sano on 2019/05/31.
//

import XCTest
import SwmCore
@testable import SwmKnots

class BraidTests: XCTestCase {
    
    typealias B = Braid<anySize>
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInitByCode() {
        let b = B(strands: 5, code: 1, 1, -2, -1)
        XCTAssertEqual(b.description, "σ₁σ₁σ₂⁻¹σ₁⁻¹")
    }

    func testClosure() {
        let b = B(strands: 5, code: 1, 2, 3, 4)
        let L = b.closure
        XCTAssertEqual(L.seifertCircles.count, 5)
    }

    func test3_1() {
        let b = B(strands: 2, code: -1, -1, -1)
        let L = b.closure
        assertJonesPolynomial(L, "3_1")
    }
    
    func test4_1() {
        let b = B(strands: 3, code: -1, 2, -1, 2)
        let L = b.closure
        assertJonesPolynomial(L, "4_1")
    }
    
    func test5_1() {
        let b = B(strands: 2, code: -1,-1,-1,-1,-1)
        let L = b.closure
        assertJonesPolynomial(L, "5_1")
    }
    
    private func assertJonesPolynomial(_ L: Link, _ name: String) {
        XCTAssertEqual(JonesPolynomial(L), JonesPolynomial(Link.load(name)!))
    }
}
