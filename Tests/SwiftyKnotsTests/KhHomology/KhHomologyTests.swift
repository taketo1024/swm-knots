//
//  KHTests.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import XCTest
import SwiftyMath
@testable import SwiftyKnots

class KhHomologyTests: XCTestCase {
    
    func testTrefoil() {
        let L = Link.trefoil
        let J = L.unnormalizedJonesPolynomial
        
        let Kh = KhHomology(L, 𝐐.self)
        let χ = Kh.gradedEulerCharacteristic.withSymbol("q")
        
        XCTAssertEqual(χ, J)
    }
}
