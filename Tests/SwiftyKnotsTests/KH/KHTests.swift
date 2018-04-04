//
//  KHTests.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import XCTest
import SwiftyMath
@testable import SwiftyKnots

class KHTests: XCTestCase {
    
    func testTrefoil() {
        let L = Link.trefoil
        let CKh = KhChainComplex<𝐐>(L)
        print(CKh.detailDescription)
    }
}
