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
    
    func test3_1_Z() {
        let K = Knot(3, 1)
        let Kh = K.KhHomology(𝐙.self)
        
        XCTAssertEqual(Kh.qEulerCharacteristic, K.JonesPolynomial(normalized: false))
    }
    
    func test4_1_Z() {
        let K = Knot(4, 1)
        let Kh = K.KhHomology(𝐙.self)
        
        XCTAssertEqual(Kh.qEulerCharacteristic, K.JonesPolynomial(normalized: false))
    }
    
    func test5_1_Z() {
        let K = Knot(5, 1)
        let Kh = K.KhHomology(𝐙.self)
        
        XCTAssertEqual(Kh.qEulerCharacteristic, K.JonesPolynomial(normalized: false))
    }
}
