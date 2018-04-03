//
//  SwiftyAlgebraTests.swift
//  SwiftyAlgebraTests
//
//  Created by Taketo Sano on 2017/05/03.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import XCTest
@testable import SwiftyAlgebra

class IntegerTests: XCTestCase {
    
    func testSum() {
        let a = 𝐙(1)
        let b = 𝐙(2)
        XCTAssertEqual(a + b, 𝐙(3))
    }
    
    func testZero() {
        let a = 𝐙(3)
        XCTAssertEqual(a + 𝐙.zero, a)
        XCTAssertEqual(𝐙.zero + a, a)
    }

    func testNeg() {
        let a = 𝐙(3)
        XCTAssertEqual(-a, 𝐙(-3))
    }

    func testMul() {
        let a = 𝐙(3)
        let b = 𝐙(2)
        XCTAssertEqual(a * b, 𝐙(6))
    }
    
    func testId() {
        let a = 𝐙(3)
        let e = 𝐙.identity
        XCTAssertEqual(a * e, a)
        XCTAssertEqual(e * a, a)
    }
    
    func testPow() {
        let a = 𝐙(2)
        XCTAssertEqual(a.pow(0), 𝐙.identity)
        XCTAssertEqual(a.pow(1), a)
        XCTAssertEqual(a.pow(2), 𝐙(4))
        XCTAssertEqual(a.pow(3), 𝐙(8))
        
        let b = 𝐙(-1)
        XCTAssertEqual(b.pow(0), 𝐙.identity)
        XCTAssertEqual(b.pow(-1), 𝐙(-1))
        XCTAssertEqual(b.pow(-2), 𝐙(1))
        XCTAssertEqual(b.pow(-3), 𝐙(-1))
    }
    
    func testIsEven() {
        XCTAssertTrue(𝐙(2).isEven)
        XCTAssertFalse(𝐙(3).isEven)
    }
    
    func testSign() {
        XCTAssertEqual(𝐙(13).sign, 1)
        XCTAssertEqual( 𝐙(0).sign, 0)
        XCTAssertEqual(𝐙(-4).sign, -1)
    }
    
    func testEucDiv() {
        let a = 𝐙(7)
        let b = 𝐙(3)
        let (q, r) = a.eucDiv(by: b)
        XCTAssertEqual(q, 𝐙(2))
        XCTAssertEqual(r, 𝐙(1))
    }
    
    func testPrimes() {
        let ps = 𝐙.primes(upto: 20)
        XCTAssertEqual(ps, [2, 3, 5, 7, 11, 13, 17, 19])
    }

    func testPrimeFactors() {
        let ps = 124.primeFactors
        XCTAssertEqual(ps, [2, 2, 31])
    }

    func testDivisors() {
        let ps = 124.divisors
        XCTAssertEqual(ps, [1, 2, 4, 31, 62, 124])
    }
}
