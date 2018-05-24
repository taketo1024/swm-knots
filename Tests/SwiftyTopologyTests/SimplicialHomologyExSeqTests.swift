//
//  SimplicialHomologyExSeqTests.swift
//  SwiftyTopologyTests
//
//  Created by Taketo Sano on 2018/05/15.
//

import XCTest
import SwiftyMath
import SwiftyHomology
@testable import SwiftyTopology

class SimplicialHomologyExSeqTests: XCTestCase {
    typealias R = 𝐙
    
    func testDS_col0() {
        var E = H_DS()
        E.fill(columns: 1, 2)
        E.solve()

        let h = E.column(0)
        
        XCTAssertEqual(h[0]!.structure, [0 : 1])
        XCTAssertEqual(h[1]!.structure, [0 : 1])
        XCTAssertTrue( h[2]!.isTrivial)
    }
    
    func testDS_col1() {
        var E = H_DS()
        E.fill(columns: 2, 0)
        E.solve()

        let h = E.column(1)
        
        XCTAssertEqual(h[0]!.structure, [0 : 1])
        XCTAssertTrue( h[1]!.isTrivial)
        XCTAssertTrue( h[2]!.isTrivial)
    }
    
    func testDS_col2() {
        var E = H_DS()
        E.fill(columns: 0, 1)
        E.solve()
        
        let h = E.column(2)
        
        XCTAssertTrue( h[0]!.isTrivial)
        XCTAssertTrue( h[1]!.isTrivial)
        XCTAssertEqual(h[2]!.structure, [0 : 1])
    }
    
    private func H_DS() -> HomologyExactSequenceSolver<Simplex, Simplex, Simplex, R> {
        let n = 2
        let D = SimplicialComplex.ball(dim: n)
        let S = D.skeleton(n - 1).named("S\(n - 1)")
        return SimplicialComplex.homologyExactSequence(D, S, R.self)
    }
    
}
