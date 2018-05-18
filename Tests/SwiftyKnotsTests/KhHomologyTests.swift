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
    
    func test3_1() {
        let K = Knot(3, 1)
        assert(K)
    }
    
    func test4_1() {
        let K = Knot(4, 1)
        assert(K)
    }
    
    func test5_1() {
        let K = Knot(5, 1)
        assert(K)
    }
    
    func assert(_ L: Link) {
        let J = L.JonesPolynomial(normalized: false)
        
        let Kh = L.KhHomology(𝐙.self)
        let χ = Kh.gradedEulerCharacteristic.asPolynomial(of: JonesPolynomial_q.self)
        
        XCTAssertEqual(χ, J)
    }
}
