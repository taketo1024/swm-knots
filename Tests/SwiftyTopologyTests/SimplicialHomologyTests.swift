//
//  HomologyTests.swift
//  SwiftyMathTests
//
//  Created by Taketo Sano on 2017/11/10.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import XCTest
import SwiftyMath
import SwiftyHomology
@testable import SwiftyTopology

class SimplicialHomologyTests: XCTestCase {
    
    func testD3_Z() {
        let K = SimplicialComplex.ball(dim: 3)
        let H = K.homology(𝐙.self)
        
        XCTAssertEqual(H.bottomDegree, 0)
        XCTAssertEqual(H.topDegree,    0)

        guard let h0 = H[0] else {
            return XCTFail()
        }
        
        XCTAssert(h0.isFree && h0.rank == 1)
    }
    
    func testS2_Z() {
        let K = SimplicialComplex.sphere(dim: 2)
        let H = K.homology(𝐙.self)
        
        XCTAssertEqual(H.bottomDegree, 0)
        XCTAssertEqual(H.topDegree,    2)
        
        guard let h0 = H[0], let h1 = H[1], let h2 = H[2] else {
            return XCTFail()
        }
        
        XCTAssert(h0.isFree && h0.rank == 1)
        XCTAssert(h1.isZero)
        XCTAssert(h2.isFree && h2.rank == 1)
    }
    
    func testD3_S2_Z() {
        let K = SimplicialComplex.ball(dim: 3)
        let L = K.skeleton(2)
        let H = K.homology(relativeTo: L, 𝐙.self)
        
        XCTAssertEqual(H.bottomDegree, 3)
        XCTAssertEqual(H.topDegree,    3)
        
        guard let h3 = H[3] else {
            return XCTFail()
        }
        
        XCTAssert(h3.isFree && h3.rank == 1)
    }
    
    func testT2_Z() {
        let K = SimplicialComplex.torus(dim: 2)
        let H = K.homology(𝐙.self)

        XCTAssertEqual(H.bottomDegree, 0)
        XCTAssertEqual(H.topDegree,    2)
        
        guard let h0 = H[0], let h1 = H[1], let h2 = H[2] else {
            return XCTFail()
        }
        
        XCTAssert(h0.isFree && h0.rank == 1)
        XCTAssert(h1.isFree && h1.rank == 2)
        XCTAssert(h2.isFree && h2.rank == 1)
    }
    
    func testRP2_Z() {
        let K = SimplicialComplex.realProjectiveSpace(dim: 2)
        let H = K.homology(𝐙.self)
        
        XCTAssertEqual(H.bottomDegree, 0)
        XCTAssertEqual(H.topDegree,    1)
        
        guard let h0 = H[0], let h1 = H[1] else {
            return XCTFail()
        }
        
        XCTAssert(h0.isFree && h0.rank == 1)
        XCTAssert(h1.summands.count == 1 && h1.torsionCoeffs[0] == 2)
    }
    
    func testD3_Z2() {
        let K = SimplicialComplex.ball(dim: 3)
        let H = K.homology(𝐙₂.self)
        
        XCTAssertEqual(H.bottomDegree, 0)
        XCTAssertEqual(H.topDegree,    0)
        
        guard let h0 = H[0] else {
            return XCTFail()
        }
        
        XCTAssert(h0.isFree && h0.rank == 1)
    }
    
    func testS2_Z2() {
        let K = SimplicialComplex.sphere(dim: 2)
        let H = K.homology(𝐙₂.self)
        
        XCTAssertEqual(H.bottomDegree, 0)
        XCTAssertEqual(H.topDegree,    2)
        
        guard let h0 = H[0], let h1 = H[1], let h2 = H[2] else {
            return XCTFail()
        }
        
        XCTAssert(h0.isFree && h0.rank == 1)
        XCTAssert(h1.isZero)
        XCTAssert(h2.isFree && h2.rank == 1)
    }
    
    func testD3_S2_Z2() {
        let K = SimplicialComplex.ball(dim: 3)
        let L = K.skeleton(2)
        let H = K.homology(relativeTo: L, 𝐙₂.self)
        
        XCTAssertEqual(H.bottomDegree, 3)
        XCTAssertEqual(H.topDegree,    3)
        
        guard let h3 = H[3] else {
            return XCTFail()
        }
        
        XCTAssert(h3.isFree && h3.rank == 1)
    }
    
    func testT2_Z2() {
        let K = SimplicialComplex.torus(dim: 2)
        let H = K.homology(𝐙₂.self)
        
        XCTAssertEqual(H.bottomDegree, 0)
        XCTAssertEqual(H.topDegree,    2)
        
        guard let h0 = H[0], let h1 = H[1], let h2 = H[2] else {
            return XCTFail()
        }
        
        XCTAssert(h0.isFree && h0.rank == 1)
        XCTAssert(h1.isFree && h1.rank == 2)
        XCTAssert(h2.isFree && h2.rank == 1)
    }
    
    func testRP2_Z2() {
        let K = SimplicialComplex.realProjectiveSpace(dim: 2)
        let H = K.homology(𝐙₂.self)
        
        XCTAssertEqual(H.bottomDegree, 0)
        XCTAssertEqual(H.topDegree,    2)
        
        guard let h0 = H[0], let h1 = H[1], let h2 = H[2] else {
            return XCTFail()
        }
        
        XCTAssert(h0.isFree && h0.rank == 1)
        XCTAssert(h1.isFree && h1.rank == 1)
        XCTAssert(h2.isFree && h2.rank == 1)
    }
    
    func testD3_Q() {
        let K = SimplicialComplex.ball(dim: 3)
        let H = K.homology(𝐐.self)
        
        XCTAssertEqual(H.bottomDegree, 0)
        XCTAssertEqual(H.topDegree,    0)
        
        guard let h0 = H[0] else {
            return XCTFail()
        }
        
        XCTAssert(h0.isFree && h0.rank == 1)
    }
    
    func testS2_Q() {
        let K = SimplicialComplex.sphere(dim: 2)
        let H = K.homology(𝐐.self)
        
        XCTAssertEqual(H.bottomDegree, 0)
        XCTAssertEqual(H.topDegree,    2)
        
        guard let h0 = H[0], let h1 = H[1], let h2 = H[2] else {
            return XCTFail()
        }
        
        XCTAssert(h0.isFree && h0.rank == 1)
        XCTAssert(h1.isZero)
        XCTAssert(h2.isFree && h2.rank == 1)
    }
    
    func testD3_S2_Q() {
        let K = SimplicialComplex.ball(dim: 3)
        let L = K.skeleton(2)
        let H = K.homology(relativeTo: L, 𝐐.self)
        
        XCTAssertEqual(H.bottomDegree, 3)
        XCTAssertEqual(H.topDegree,    3)
        
        guard let h3 = H[3] else {
            return XCTFail()
        }
        
        XCTAssert(h3.isFree && h3.rank == 1)
    }
    
    func testT2_Q() {
        let K = SimplicialComplex.torus(dim: 2)
        let H = K.homology(𝐐.self)
        
        XCTAssertEqual(H.bottomDegree, 0)
        XCTAssertEqual(H.topDegree,    2)
        
        guard let h0 = H[0], let h1 = H[1], let h2 = H[2] else {
            return XCTFail()
        }
        
        XCTAssert(h0.isFree && h0.rank == 1)
        XCTAssert(h1.isFree && h1.rank == 2)
        XCTAssert(h2.isFree && h2.rank == 1)
    }
    
    func testRP2_Q() {
        let K = SimplicialComplex.realProjectiveSpace(dim: 2)
        let H = K.homology(𝐐.self)
        
        XCTAssertEqual(H.bottomDegree, 0)
        XCTAssertEqual(H.topDegree,    0)
        
        guard let h0 = H[0] else {
            return XCTFail()
        }
        
        XCTAssert(h0.isFree && h0.rank == 1)
    }
}
