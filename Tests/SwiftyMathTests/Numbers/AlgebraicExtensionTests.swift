//
//  SwiftyMathTests.swift
//  SwiftyMathTests
//
//  Created by Taketo Sano on 2017/05/03.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import XCTest
@testable import SwiftyMath

class AlgebraicExtensionTests: XCTestCase {
    
    struct p1: IrrPolynomialTP { static var value = Polynomial<𝐐>(coeffs: -2, 0, 1) }
    typealias A = AlgebraicExtension<𝐐, p1>
    let α = A(.indeterminate)
    
    struct p2: IrrPolynomialTP { static var value = Polynomial<A>(coeffs: -3, 0, 1) }
    typealias B = AlgebraicExtension<A, p2>
    let β = B(.indeterminate)

    func testIsField() {
        XCTAssertTrue(A.isField)
    }
    
    func testIntLiteral() {
        let a: A = 2
        XCTAssertEqual(a, A(2))
    }
    
    func testFromInt() {
        let a = A(from: 1)
        XCTAssertEqual(a, A(1))
    }
    
    func testFromRational() {
        let a = A(from: 𝐐(2, 3))
        XCTAssertEqual(a, A(𝐐(2, 3)))
    }
    
    func testSum() {
        let a = 1 + 2 * α
        let b = 3 + 4 * α
        XCTAssertEqual(a + b, 4 + 6 * α)
    }
    
    func testZero() {
        let a = 1 + 2 * α
        let o = A.zero
        XCTAssertEqual(o + o, o)
        XCTAssertEqual(a + o, a)
        XCTAssertEqual(o + a, a)
    }
    
    func testNeg() {
        let a = 1 + 2 * α
        XCTAssertEqual(-a, -1 - 2 * α)
    }
    
    func testExtension() {
        XCTAssertEqual(α * α, 2)
        XCTAssertEqual(β * β, 3)
    }
    
    func testMul() {
        let a = 1 + 2 * α
        let b = 3 + 4 * α
        XCTAssertEqual(a * b, 19 + 10 * α)
    }
    
    func testId() {
        let a = 3 + 4 * α
        let e = A.identity
        XCTAssertEqual(e * e, e)
        XCTAssertEqual(a * e, a)
        XCTAssertEqual(e * a, a)
    }
    
    func testInv() {
        XCTAssertEqual(α.inverse!, A(Polynomial(coeffs: 0, 𝐐(1, 2))))
        
        let a = 1 + 3 * α
        XCTAssertEqual(a.inverse!, A(Polynomial(coeffs: 𝐐(-1, 17), 𝐐(3, 17))))

        let o = A.zero
        XCTAssertNil(o.inverse)
    }
    
    func testPow() {
        let a = 1 + 2 * α
        XCTAssertEqual(a.pow(0), 1)
        XCTAssertEqual(a.pow(1), 1 + 2 * α)
        XCTAssertEqual(a.pow(2), 9 + 4 * α)
        
        XCTAssertEqual(a.pow(-1), A(Polynomial(coeffs: 𝐐(-1, 7), 𝐐(2, 7))))
        XCTAssertEqual(a.pow(-2), A(Polynomial(coeffs: 𝐐(9, 49), 𝐐(-4, 49))))

    }
}
