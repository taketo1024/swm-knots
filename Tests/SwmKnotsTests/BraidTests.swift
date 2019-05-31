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
    
    typealias B = Braid<_5>

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDescription() {
        let b = B.produce(code: 1, 2, 2, -3, 1, 1)
        XCTAssertEqual(b.description, "σ₁²σ₂⁻³σ₁")
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func test() {
        let b = B.produce(code: 1, 2, 2, -3, 1, 1, 3, 1)
        b.describe()
    }
}
