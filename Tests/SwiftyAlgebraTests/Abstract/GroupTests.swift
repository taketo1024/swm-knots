//
//  SwiftyAlgebraTests.swift
//  SwiftyAlgebraTests
//
//  Created by Taketo Sano on 2017/05/03.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import XCTest
@testable import SwiftyAlgebra

class GroupTests: XCTestCase {
    private struct A: Group {
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
        
        var inverse: A {
            return A(value: -value)
        }
    }
    
    private struct B: NormalSubgroup {
        typealias Super = A
        
        private let a: A
        init(_ a: A) {
            self.a = a
        }
        
        var asSuper: A {
            return a
        }
        
        static func contains(_ a: GroupTests.A) -> Bool {
            return a.value % 3 == 0
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
    
    func testInverse() {
        let a = A(value: 3)
        XCTAssertEqual(a.inverse, A(value: -3))
    }
    
    func testPow() {
        let a = A(value: 2)
        XCTAssertEqual(a.pow(0), A.identity)
        XCTAssertEqual(a.pow(1), a)
        XCTAssertEqual(a.pow(2), A(value: 4))
        XCTAssertEqual(a.pow(3), A(value: 6))
        XCTAssertEqual(a.pow(-1), a.inverse)
        XCTAssertEqual(a.pow(-2), A(value: -4))
        XCTAssertEqual(a.pow(-3), A(value: -6))
    }
    
    func testSubgroupMul() {
        let a = B(A(value: 3))
        let b = B(A(value: 4))
        XCTAssertEqual(a * b, B(A(value: 7)))
    }
    
    func testSubgroupIdentity() {
        let a = B(A(value: 3))
        let e = B.identity
        XCTAssertEqual(e * e, e)
        XCTAssertEqual(a * e, a)
        XCTAssertEqual(e * a, a)
    }
    
    func testSubgroupInverse() {
        let a = B(A(value: 3))
        XCTAssertEqual(a.inverse, B(A(value: -3)))
        XCTAssertEqual(a * a.inverse, B.identity)
        XCTAssertEqual(a.inverse * a, B.identity)
    }
    
    func testProductGroupMul() {
        typealias P = ProductGroup<A, A>
        let a = P(A(value: 1), A(value: 2))
        let b = P(A(value: 3), A(value: 4))
        XCTAssertEqual(a * b, P(A(value: 4), A(value: 6)))
    }
    
    func testProductGroupIdentity() {
        typealias P = ProductGroup<A, A>
        let a = P(A(value: 1), A(value: 2))
        let e = P.identity
        XCTAssertEqual(e * e, e)
        XCTAssertEqual(a * e, a)
        XCTAssertEqual(e * a, a)
    }
    
    func testProductGroupInverse() {
        typealias P = ProductGroup<A, A>
        let a = P(A(value: 3), A(value: 4))
        XCTAssertEqual(a.inverse, P(A(value: -3), A(value: -4)))
    }
    
    func testQuotientGroupMul() {
        typealias Q = QuotientGroup<A, B>
        let a = Q(A(value: 1))
        let b = Q(A(value: 2))
        XCTAssertEqual(a * b, Q(A(value: 0)))
    }
    
    func testQuotientGroupIdentity() {
        typealias Q = QuotientGroup<A, B>
        let a = Q(A(value: 1))
        let e = Q.identity
        XCTAssertEqual(e * e, e)
        XCTAssertEqual(a * e, a)
        XCTAssertEqual(e * a, a)
    }
    
    func testQuotientGroupInverse() {
        typealias Q = QuotientGroup<A, B>
        let a = Q(A(value: 1))
        XCTAssertEqual(a.inverse, Q(A(value: 2)))
    }
    
    func testGroupHom() {
        typealias F = GroupHom<A, A>
        let f = F { a in A(value: a.value * 2) }
        let a = A(value: 3)
        XCTAssertEqual(f.applied(to: a), A(value: 6))
    }
}
