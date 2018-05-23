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

/*
class SimplicialHomologyExSeqTests: XCTestCase {
    typealias R = 𝐙
    
    func testH_DS01() {
        let E = H_DS(0, 1)
        XCTAssertTrue( E[0, 2]!.isTrivial)
        XCTAssertTrue( E[1, 2]!.isTrivial)
        XCTAssertTrue( E[2, 2]!.isFree)
        XCTAssertEqual(E[2, 2]!.rank, 1)
    }
    
    func testH_DS12() {
        let E = H_DS(1, 2)
        XCTAssertTrue( E[0, 0]!.isFree)
        XCTAssertEqual(E[0, 0]!.rank, 1)
        XCTAssertTrue( E[1, 0]!.isFree)
        XCTAssertEqual(E[1, 0]!.rank, 1)
        XCTAssertTrue( E[2, 0]!.isTrivial)
    }
    
    func testH_DS20() {
        let E = H_DS(2, 0)
        XCTAssertTrue( E[0, 1]!.isFree)
        XCTAssertEqual(E[0, 1]!.rank, 1)
        XCTAssertTrue( E[1, 1]!.isTrivial)
        XCTAssertTrue( E[2, 1]!.isTrivial)
    }
    
    func testCH_DS01() {
        let E = CH_DS(0, 1)
        XCTAssertTrue( E[0, 2]!.isFree)
        XCTAssertEqual(E[0, 2]!.rank, 1)
        XCTAssertTrue( E[1, 2]!.isFree)
        XCTAssertEqual(E[1, 2]!.rank, 1)
        XCTAssertTrue( E[2, 2]!.isTrivial)
    }
    
    func testCH_DS12() {
        let E = CH_DS(1, 2)
        XCTAssertTrue( E[0, 0]!.isTrivial)
        XCTAssertTrue( E[1, 0]!.isTrivial)
        XCTAssertTrue( E[2, 0]!.isFree)
        XCTAssertEqual(E[2, 0]!.rank, 1)
    }
    
    func testCH_DS20() {
        let E = CH_DS(2, 0)
        XCTAssertTrue( E[0, 1]!.isFree)
        XCTAssertEqual(E[0, 1]!.rank, 1)
        XCTAssertTrue( E[1, 1]!.isTrivial)
        XCTAssertTrue( E[2, 1]!.isTrivial)
    }
    
    private func H_DS(_ i0: Int, _ i1: Int) -> HomologyExactSequence<R> {
        let n = 2
        let D = SimplicialComplex.ball(dim: n)
        let S = D.skeleton(n - 1).named("S\(n - 1)")
        
        var E = HomologyExactSequence.pair(D, S, R.self)
        E.fill(columns: i0, i1)
        E.solve()
        return E
    }
    
    private func CH_DS(_ i0: Int, _ i1: Int) -> CohomologyExactSequence<R> {
        let n = 2
        let D = SimplicialComplex.ball(dim: n)
        let S = D.skeleton(n - 1).named("S\(n - 1)")
        
        var E = CohomologyExactSequence.pair(D, S, R.self)
        E.fill(columns: i0, i1)
        E.solve()
        
        return E
    }
}
*/
