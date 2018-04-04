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
    
    typealias A = LaurentPolynomial<𝐐>
    
    func testTrefoil() {
        let L = Link.trefoil
        let CKh = L.KhovanovChainComplex
        print(CKh.detailDescription)
    }
}
