//
//  SwiftyMathTests.swift
//  SwiftyMathTests
//
//  Created by Taketo Sano on 2017/05/03.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import XCTest
@testable import SwiftyMath

class MatrixTests: XCTestCase {
    
    typealias A = Matrix2<𝐙>
    
    func testInitByGenerator() {
        let a = A { (i, j) in i * 10 + j}
        XCTAssertEqual(a, A(0,1,10,11))
    }
    
    func testInitByComponents() {
        let a = A(components: [(0,0,3), (0,1,2), (1,1,5)])
        XCTAssertEqual(a, A(3,2,0,5))
    }
    
    func testInitWithMissingGrid() {
        let a = A(1,2,3)
        XCTAssertEqual(a, A(1,2,3,0))
    }
    
    func testInitWithTooMuchGrid() {
        let a = A(1,2,3,4,5,6)
        XCTAssertEqual(a, A(1,2,3,4))
    }
    
    func testSum() {
        let a = A(1,2,3,4)
        let b = A(2,3,4,5)
        XCTAssertEqual(a + b, A(3,5,7,9))
    }
    
    func testZero() {
        let a = A(1,2,3,4)
        let o = A.zero
        XCTAssertEqual(a + o, a)
        XCTAssertEqual(o + a, a)
    }

    func testNeg() {
        let a = A(1,2,3,4)
        XCTAssertEqual(-a, A(-1,-2,-3,-4))
    }

    func testMul() {
        let a = A(1,2,3,4)
        let b = A(2,3,4,5)
        XCTAssertEqual(a * b, A(10,13,22,29))
    }
    
    func testScalarMul() {
        let a = A(1,2,3,4)
        XCTAssertEqual(2 * a, A(2,4,6,8))
        XCTAssertEqual(a * 3, A(3,6,9,12))
    }
    
    func testId() {
        let a = A(1,2,3,4)
        let e = A.identity
        XCTAssertEqual(a * e, a)
        XCTAssertEqual(e * a, a)
    }
    
    func testInv() {
        let a = A(1,2,2,3)
        XCTAssertEqual(a.inverse!, A(-3,2,2,-1))
        
        let b = A(1,2,3,4)
        XCTAssertNil(b.inverse)
    }
    
    func testPow() {
        let a = A(1,2,3,4)
        XCTAssertEqual(a.pow(0), A.identity)
        XCTAssertEqual(a.pow(1), a)
        XCTAssertEqual(a.pow(2), A(7,10,15,22))
        XCTAssertEqual(a.pow(3), A(37,54,81,118))
    }
    
    func testTrace() {
        let a = A(1,2,3,4)
        XCTAssertEqual(a.trace, 5)
    }
    
    func testDet() {
        let a = A(1,2,3,4)
        XCTAssertEqual(a.determinant, -2)
    }
    
    func testTransposed() {
        let a = A(1,2,3,4)
        XCTAssertEqual(a.transposed, A(1,3,2,4))
    }
}
