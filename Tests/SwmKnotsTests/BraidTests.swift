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

    func testInitByCode() {
        let b = B(code: 1, 1, -2, -1)
        XCTAssertEqual(b.description, "σ₁σ₁σ₂⁻¹σ₁⁻¹")
        print(b.detailDescription)
    }
}
