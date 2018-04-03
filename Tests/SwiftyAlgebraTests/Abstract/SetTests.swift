//
//  SwiftyAlgebraTests.swift
//  SwiftyAlgebraTests
//
//  Created by Taketo Sano on 2017/05/03.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import XCTest
@testable import SwiftyAlgebra

fileprivate struct A: SetType {
    public let value: Int
    public var description: String {
        return value.description
    }
}

fileprivate struct B: SubsetType {
    public typealias Super = A
    
    private let a: A
    init(_ a: A) {
        self.a = a
    }
    
    var asSuper: A {
        return a
    }
    
    static func contains(_ a: A) -> Bool {
        return a.value % 2 == 0
    }
}

fileprivate struct C: FiniteSetType {
    static var allElements: [C] {
        return [C()]
    }
    
    static var countElements: Int {
        return 1
    }
    
    var description: String {
        return "c"
    }
}

class SetTests: XCTestCase {
    
    func testSymbol() {
        XCTAssertEqual(A.symbol, "A")
    }
    
    func testEquality() {
        let a1 = A(value: 1)
        let a2 = A(value: 2)
        XCTAssertTrue(a1 == a1)
        XCTAssertTrue(a1 != a2)
    }
    
    func testSubsetType() {
        let b = B(A(value: 0))
        XCTAssertEqual(b.description, "0")
        XCTAssertTrue(B.contains(A(value: 0)))
        XCTAssertFalse(B.contains(A(value: 1)))
    }
    
    func testFiniteSetType() {
        XCTAssertEqual(C.countElements, 1)
        XCTAssertEqual(C.allElements, [C()])
    }
    
    func testProductSet() {
        typealias P = ProductSet<A, A>
        let a1 = P(A(value: 1), A(value: 2))
        let a2 = P(A(value: 3), A(value: 4))
        XCTAssertEqual(P.symbol, "A×A")
        XCTAssertEqual(a1.description, "(1, 2)")
        XCTAssertEqual(a1, a1)
        XCTAssertNotEqual(a1, a2)
    }
}
