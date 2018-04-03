//
//  SwiftyAlgebraTests.swift
//  SwiftyAlgebraTests
//
//  Created by Taketo Sano on 2017/05/03.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import XCTest
@testable import SwiftyAlgebra

class MonoidTests: XCTestCase {
    private struct A: Monoid {
        let value: Int
        var description: String {
            return value.description
        }
        
        static func * (a: A, b: A) -> A {
            return A(value: a.value + b.value)
        }
        
        static var identity: A {
            return A(value: 0)
        }
    }
    
    private struct B: Submonoid {
        typealias Super = A

        let a: A
        init(_ a: A) {
            self.a = a
        }
        
        var asSuper: A {
            return a
        }
        
        static func contains(_ a: A) -> Bool {
            return true
        }
    }
    
    func testMul() {
        let a = A(value: 3)
        let b = A(value: 4)
        XCTAssertEqual(a * b, A(value: 7))
    }
    
    func testIdentity() {
        let e = A.identity
        let a = A(value: 3)
        XCTAssertEqual(a * e, a)
        XCTAssertEqual(e * a, a)
    }
    
    func testPow() {
        let a = A(value: 2)
        XCTAssertEqual(a.pow(0), A.identity)
        XCTAssertEqual(a.pow(1), a)
        XCTAssertEqual(a.pow(2), A(value: 4))
        XCTAssertEqual(a.pow(3), A(value: 6))
    }
    
    func testSubmonoidMul() {
        let a = B(A(value: 3))
        let b = B(A(value: 4))
        XCTAssertEqual(a * b, B(A(value: 7)))
    }
    
    func testSubmonoidIdentity() {
        let a = B(A(value: 3))
        let e = B.identity
        XCTAssertEqual(e * e, e)
        XCTAssertEqual(a * e, a)
        XCTAssertEqual(e * a, a)
    }
    
    func testProductMonoidMul() {
        typealias P = ProductMonoid<A, A>
        let a = P(A(value: 1), A(value: 2))
        let b = P(A(value: 3), A(value: 4))
        XCTAssertEqual(a * b, P(A(value: 4), A(value: 6)))
    }
    
    func testProductMonoidIdentity() {
        typealias P = ProductMonoid<A, A>
        let a = P(A(value: 1), A(value: 2))
        let e = P.identity
        XCTAssertEqual(e * e, e)
        XCTAssertEqual(a * e, a)
        XCTAssertEqual(e * a, a)
    }
    
    func testMonoidHom() {
        typealias F = MonoidHom<A, A>
        let f = F { a in A(value: a.value * 2) }
        let a = A(value: 3)
        XCTAssertEqual(f.applied(to: a), A(value: 6))
    }
}
