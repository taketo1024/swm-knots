//
//  HomologyTests.swift
//  SwiftyAlgebraTests
//
//  Created by Taketo Sano on 2017/11/10.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import XCTest
import SwiftyAlgebra
@testable import SwiftyTopology

class SimplicialHomologyExSeqTests: XCTestCase {
    
    typealias H<R: EuclideanRing> = Homology<Simplex, R>
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test1() {
        let n = 2
        let D = SimplicialComplex.ball(dim: n)
        let S = D.boundary.named("S^\(n-1)")
        
        var E = HomologyExactSequence.pair(D, S, Z.self)
        
        E.fill(column: 0)
        E.fill(column: 1)
        
        let h = E.solve(column: 2).map{ $0! }
        
        XCTAssert(h[0].isTrivial)
        XCTAssert(h[1].isTrivial)
        XCTAssert(h[2].isFree && h[2].rank == 1)
    }
    
    func test2() {
        let n = 2
        let X = SimplicialComplex.torus(dim: n)
        let s = X.cells(ofDim: n)[0]
        
        let A = (X - s).named("A")
        let B = s.asComplex.named("B")
        
        var E = HomologyExactSequence.MayerVietoris(X, A, B, Z.self)
        
        E.fill(column: 0)
        E.fill(column: 1)
        
        let h = E.solve(column: 2).map{ $0! }
        
        XCTAssert(h[0].isFree && h[0].rank == 1)
        XCTAssert(h[1].isFree && h[1].rank == 2)
        XCTAssert(h[2].isFree && h[2].rank == 1)
    }
}
