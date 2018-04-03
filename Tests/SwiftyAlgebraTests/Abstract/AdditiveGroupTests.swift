//
//  SwiftyAlgebraTests.swift
//  SwiftyAlgebraTests
//
//  Created by Taketo Sano on 2017/05/03.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import XCTest
@testable import SwiftyAlgebra

class AdditiveGroupTests: XCTestCase {
    private struct A: AdditiveGroup {
        let value: Int
        var description: String {
            return value.description
        }
        
        static func + (a: A, b: A) -> A {
            return A(value: a.value + b.value)
        }
        
        static var zero: A {
            return A(value: 0)
        }
        
        static prefix func - (x: A) -> A {
            return A(value: -x.value)
        }
    }
    
    private struct B: AdditiveSubgroup {
        typealias Super = A
        
        private let a: A
        init(_ a: A) {
            self.a = a
        }
        
        var asSuper: A {
            return a
        }
        
        static func contains(_ a: AdditiveGroupTests.A) -> Bool {
            return a.value % 3 == 0
        }
        
    }
    
    func testSum() {
        let a = A(value: 3)
        let b = A(value: 4)
        XCTAssertEqual(a + b, A(value: 7))
    }
    
    func testZero() {
        let e = A.zero
        let a = A(value: 3)
        XCTAssertEqual(a + e, a)
        XCTAssertEqual(e + a, a)
    }
    
    func testNegative() {
        let a = A(value: 3)
        XCTAssertEqual(-a, A(value: -3))
    }
    
    func testSubgroupSum() {
        let a = B(A(value: 3))
        let b = B(A(value: 4))
        XCTAssertEqual(a + b, B(A(value: 7)))
    }
    
    func testSubgroupZero() {
        let a = B(A(value: 3))
        let e = B.zero
        XCTAssertEqual(e + e, e)
        XCTAssertEqual(a + e, a)
        XCTAssertEqual(e + a, a)
    }
    
    func testSubgroupNegative() {
        let a = B(A(value: 3))
        XCTAssertEqual(-a, B(A(value: -3)))
    }
    
    func testAdditiveProductGroupSum() {
        typealias P = AdditiveProductGroup<A, A>
        let a = P(A(value: 1), A(value: 2))
        let b = P(A(value: 3), A(value: 4))
        XCTAssertEqual(a + b, P(A(value: 4), A(value: 6)))
    }
    
    func testAdditiveProductGroupZero() {
        typealias P = AdditiveProductGroup<A, A>
        let a = P(A(value: 1), A(value: 2))
        let e = P.zero
        XCTAssertEqual(e + e, e)
        XCTAssertEqual(a + e, a)
        XCTAssertEqual(e + a, a)
    }
    
    func testAdditiveProductGroupNegative() {
        typealias P = AdditiveProductGroup<A, A>
        let a = P(A(value: 3), A(value: 4))
        XCTAssertEqual(-a, P(A(value: -3), A(value: -4)))
    }
    
    func testAdditiveQuotientGroupSum() {
        typealias Q = AdditiveQuotientGroup<A, B>
        let a = Q(A(value: 1))
        let b = Q(A(value: 2))
        XCTAssertEqual(a + b, Q(A(value: 0)))
    }
    
    func testAdditiveQuotientGroupZero() {
        typealias Q = AdditiveQuotientGroup<A, B>
        let a = Q(A(value: 1))
        let e = Q.zero
        XCTAssertEqual(e + e, e)
        XCTAssertEqual(a + e, a)
        XCTAssertEqual(e + a, a)
    }
    
    func testAdditiveQuotientGroupNegative() {
        typealias Q = AdditiveQuotientGroup<A, B>
        let a = Q(A(value: 1))
        XCTAssertEqual(-a, Q(A(value: 2)))
    }
    
    func testAdditiveGroupHom() {
        typealias F = AdditiveGroupHom<A, A>
        let f = F { a in A(value: a.value * 2) }
        let a = A(value: 3)
        XCTAssertEqual(f.applied(to: a), A(value: 6))
    }
}
