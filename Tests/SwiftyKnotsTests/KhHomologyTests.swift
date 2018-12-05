//
//  KHTests.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import XCTest
import SwiftyMath
import SwiftyHomology
@testable import SwiftyKnots

class KhovanovHomologyTests: XCTestCase {
    
    private func χ<R: Ring>(_ Kh: ModuleGrid2<KhBasisElement, R>) -> LaurentPolynomial<𝐙, JonesPolynomial_q>  {
        return Kh.gradedEulerCharacteristic(𝐙.self, JonesPolynomial_q.self)
    }
    
    func testUnknot() {
        let K = Link.unknot
        let Kh = K.KhovanovHomology(𝐙.self)
        
        XCTAssertEqual(χ(Kh), K.JonesPolynomial(normalized: false))
        XCTAssertEqual(Kh.indices.count, 2)
        XCTAssertEqual(Kh[0, -1]!.structure, [0 : 1])
        XCTAssertEqual(Kh[0,  1]!.structure, [0 : 1])
        XCTAssertEqual(K.RasmussenInvariant, 0)
    }
    
    func testUnknot_RM1() {
        let K = Link(planarCode: [1,2,2,1])
        let Kh = K.KhovanovHomology(𝐙.self)
        
        XCTAssertEqual(Kh.structureCode, Link.unknot.KhovanovHomology(𝐙.self).structureCode)
        XCTAssertEqual(K.RasmussenInvariant, 0)
    }
    
    func testUnknot_RM2() {
        let K = Link(planarCode: [1,4,2,1], [2,4,3,3])
        let Kh = K.KhovanovHomology(𝐙.self)
        
        XCTAssertEqual(Kh.structureCode, Link.unknot.KhovanovHomology(𝐙.self).structureCode)
        XCTAssertEqual(K.RasmussenInvariant, 0)
    }
    
    func test3_1_Z() {
        let K = Knot(3, 1)
        let Kh = K.KhovanovHomology(𝐙.self)
        
        XCTAssertEqual(χ(Kh), K.JonesPolynomial(normalized: false))
        
        XCTAssertEqual(Kh.indices.count, 5)
        XCTAssertEqual(Kh[-3, -9]!.structure, [0 : 1])
        XCTAssertEqual(Kh[-2, -7]!.structure, [2 : 1])
        XCTAssertEqual(Kh[-2, -5]!.structure, [0 : 1])
        XCTAssertEqual(Kh[-0, -3]!.structure, [0 : 1])
        XCTAssertEqual(Kh[-0, -1]!.structure, [0 : 1])
        
        XCTAssertEqual(K.RasmussenInvariant, -2)
    }
    
    func test4_1_Z() {
        let K = Knot(4, 1)
        let Kh = K.KhovanovHomology(𝐙.self)
        
        XCTAssertEqual(χ(Kh), K.JonesPolynomial(normalized: false))
        
        XCTAssertEqual(Kh.indices.count, 8)
        XCTAssertEqual(Kh[-2, -5]!.structure, [0 : 1])
        XCTAssertEqual(Kh[-1, -3]!.structure, [2 : 1])
        XCTAssertEqual(Kh[-1, -1]!.structure, [0 : 1])
        XCTAssertEqual(Kh[ 0, -1]!.structure, [0 : 1])
        XCTAssertEqual(Kh[ 0, -1]!.structure, [0 : 1])
        XCTAssertEqual(Kh[ 1,  1]!.structure, [0 : 1])
        XCTAssertEqual(Kh[ 2,  3]!.structure, [2 : 1])
        XCTAssertEqual(Kh[ 2,  5]!.structure, [0 : 1])
        
        XCTAssertEqual(K.RasmussenInvariant, 0)
    }
    
    func test5_1_Z() {
        let K = Knot(5, 1)
        let Kh = K.KhovanovHomology(𝐙.self)
        
        XCTAssertEqual(Kh.indices.count, 8)
        XCTAssertEqual(Kh[-5, -15]!.structure, [0 : 1])
        XCTAssertEqual(Kh[-4, -13]!.structure, [2 : 1])
        XCTAssertEqual(Kh[-4, -11]!.structure, [0 : 1])
        XCTAssertEqual(Kh[-3, -11]!.structure, [0 : 1])
        XCTAssertEqual(Kh[-2,  -9]!.structure, [2 : 1])
        XCTAssertEqual(Kh[-2,  -7]!.structure, [0 : 1])
        XCTAssertEqual(Kh[ 0,  -5]!.structure, [0 : 1])
        XCTAssertEqual(Kh[ 0,  -3]!.structure, [0 : 1])

        XCTAssertEqual(K.RasmussenInvariant, -4)
    }
}
