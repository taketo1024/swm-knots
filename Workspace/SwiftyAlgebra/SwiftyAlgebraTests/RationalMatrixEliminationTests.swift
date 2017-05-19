//
//  MatrixDecompositionTest.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/09.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

import XCTest
@testable import SwiftyAlgebra

class RationalMatrixEliminationTests: XCTestCase {
    
    typealias M55 = Matrix<Q, _5, _5>
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    /* TODO
    func testOverflow() {
        let A = M55(6, 6, 5, 14, 15,
                    14, 6, 6, 5, 8,
                    14, 14, 10, 6, 14,
                    8, 8, 11, 11, 7,
                    10, 14, 5, 14, 14)
        let E = A.eliminate()
        XCTAssertNoThrow(E.rankNormalForm == E.left * A * E.right)
    }
     */
    
    func testEliminationRandomM55() {
        for _ in 0 ..< 10 {
            let A = randomM55()
            let E = A.eliminate()
            XCTAssertEqual(E.rankNormalForm, E.left * A * E.right, "B = LAR")
            XCTAssertEqual(A, E.leftInverse * E.rankNormalForm * E.rightInverse, "A = L^-1 B R^-1")
            XCTAssertTrue(E.rankNormalForm.reduce(true) { (res, itr) in
                res && ( (itr.col == itr.row && itr.col < E.rank) || itr.value == 0)
            }, "B is diagonal")
        }
    }
    
    func testEliminationRegularM55() {
        for _ in 0 ..< 10 {
            let A = randomRegularM55()
            let E = A.eliminate()
            XCTAssertEqual(E.rankNormalForm, M55.identity, "B = I")
            XCTAssertEqual(E.rankNormalForm, E.left * A * E.right, "B = LAR")
            XCTAssertEqual(A, E.leftInverse * E.rankNormalForm * E.rightInverse, "A = L^-1 B R^-1")
        }
    }
    
    func testEliminationSingularM55() {
        for _ in 0 ..< 10 {
            let A = randomSingularM55()
            let E = A.eliminate()
            XCTAssertEqual(E.rankNormalForm, E.left * A * E.right, "B = LAR")
            XCTAssertEqual(A, E.leftInverse * E.rankNormalForm * E.rightInverse, "A = L^-1 B R^-1")
            XCTAssertTrue(E.rankNormalForm.reduce(true) { (res, itr) in
                res && ( (itr.col == itr.row && itr.col < E.rank) || itr.value == 0)
            }, "B is diagonal")
        }
    }
    
    func testRowEliminationRandomM55() {
        for _ in 0 ..< 10 {
            let A = randomM55()
            let E = A.eliminate(mode: .Rows)
            XCTAssertEqual(E.right, M55.identity)
            XCTAssertEqual(E.rankNormalForm, E.left * A)
            XCTAssertEqual(A, E.leftInverse * E.rankNormalForm)
        }
    }
    
    func testRowEliminationRegularM55() {
        for _ in 0 ..< 10 {
            let A = randomRegularM55()
            let E = A.eliminate(mode: .Rows)
            XCTAssertEqual(E.right, M55.identity)
            XCTAssertEqual(E.rankNormalForm, E.left * A)
            XCTAssertEqual(A, E.leftInverse * E.rankNormalForm)
            XCTAssertEqual(E.rankNormalForm, M55.identity)
        }
    }
    
    func testRowEliminationSingularM55() {
        for _ in 0 ..< 10 {
            let A = randomSingularM55()
            let E = A.eliminate(mode: .Rows)
            XCTAssertEqual(E.right, M55.identity)
            XCTAssertEqual(E.rankNormalForm, E.left * A)
            XCTAssertEqual(A, E.leftInverse * E.rankNormalForm)
        }
    }
    
    func testColEliminationRandomM55() {
        for _ in 0 ..< 10 {
            let A = randomM55()
            let E = A.eliminate(mode: .Cols)
            XCTAssertEqual(E.left, M55.identity)
            XCTAssertEqual(E.rankNormalForm, A * E.right)
            XCTAssertEqual(A, E.rankNormalForm * E.rightInverse)
        }
    }
    
    func testColEliminationRegularM55() {
        for _ in 0 ..< 10 {
            let A = randomRegularM55()
            let E = A.eliminate(mode: .Cols)
            XCTAssertEqual(E.left, M55.identity)
            XCTAssertEqual(E.rankNormalForm, A * E.right)
            XCTAssertEqual(A, E.rankNormalForm * E.rightInverse)
            XCTAssertEqual(E.rankNormalForm, M55.identity)
        }
    }
    
    func testColEliminationSingularM55() {
        for _ in 0 ..< 10 {
            let A = randomSingularM55()
            let E = A.eliminate(mode: .Cols)
            XCTAssertEqual(E.left, M55.identity)
            XCTAssertEqual(E.rankNormalForm, A * E.right)
            XCTAssertEqual(A, E.rankNormalForm * E.rightInverse)
        }
    }
    
    private func rand(_ i: Int) -> Int {
        return Int(arc4random()) % i
    }
    
    private func rand(_ r: CountableRange<Int>) -> Int {
        return Int(arc4random()) % (r.upperBound - r.lowerBound) - r.lowerBound
    }
    
    private func rand(_ r: CountableClosedRange<Int>) -> Int {
        return rand(r.lowerBound ..< r.upperBound + 1)
    }
    
    private func randomM55(bound b: Int = 5) -> M55 {
        return M55 { _,_ in  Q(rand(-b ... b)) }
    }
    
    private func randomRegularM55(shuffle s: Int = 30) -> M55 {
        var A = M55.identity
        
        for _ in 0 ..< s {
            let i = rand(5)
            let j = rand(5)
            if i == j {
                continue
            }
            
            switch rand(6) {
            case 0: A.addRow(at: i, to: j)
            case 1: A.multiplyRow(at: i, by: -1)
            case 2: A.swapRows(i, j)
            case 3: A.addCol(at: i, to: j)
            case 4: A.multiplyCol(at: i, by: -1)
            case 5: A.swapCols(i, j)
            default: ()
            }
        }
        
        return A
    }
    
    private func randomSingularM55(shuffle s: Int = 10) -> M55 {
        let r = rand(4)
        var A = M55(){ $0 == $1 && $0 < r ? 1 : 0 }
        
        for _ in 0 ..< s {
            let i = rand(5)
            let j = rand(5)
            if i == j {
                continue
            }
            
            switch rand(6) {
            case 0: A.addRow(at: i, to: j)
            case 1: A.multiplyRow(at: i, by: Q(rand(1 ... 3)))
            case 2: A.swapRows(i, j)
            case 3: A.addCol(at: i, to: j)
            case 4: A.multiplyCol(at: i, by: Q(rand(1 ... 3)))
            case 5: A.swapCols(i, j)
            default: ()
            }
        }
        
        return A
    }
}
