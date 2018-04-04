//
//  LinkTests.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import XCTest
import SwiftyMath
@testable import SwiftyKnots

class LinkTests: XCTestCase {
    
    
    func testEmpty() {
        let e = Link.empty
        XCTAssertEqual(e.components, 0)
        XCTAssertEqual(e.crossingNumber, 0)
    }

    func testUnknot() {
        let O = Link.unknot
        XCTAssertEqual(O.components, 1)
        XCTAssertEqual(O.crossingNumber, 0)
    }
}
