//
//  ModuleObjectTests.swift
//  SwiftyMathTests
//
//  Created by Taketo Sano on 2018/04/23.
//

import XCTest
import SwiftyMath
@testable import SwiftyHomology

class ModuleObjectTests: XCTestCase {
    
    typealias A = AbstractBasisElement
    typealias R = 𝐙
    typealias M = FreeModule<A, R>
    typealias S = ModuleObject<A, R>

    func testFree() {
        let basis = (0 ..< 3).map{ M.wrap(A($0)) }
        let (e0, e1, e2) = (basis[0], basis[1], basis[2])
        let str = S(basis: basis)
        
        XCTAssertEqual(str.rank, 3)
        XCTAssertEqual(str.factorize(e0), [1, 0, 0])
        XCTAssertEqual(str.factorize(e1), [0, 1, 0])
        XCTAssertEqual(str.factorize(e2), [0, 0, 1])
    }
    
    func testFreeSub() {
        let basis = (0 ..< 3).map{ M.wrap(A($0)) }
        let (e0, e1, e2) = (basis[0], basis[1], basis[2])
        
        let a = e0 + e1
        let b = e2
        
        let str = S(basis: [a, b])
        
        XCTAssertEqual(str.rank, 2)
        XCTAssertEqual(str.factorize(a), [1, 0])
        XCTAssertEqual(str.factorize(b), [0, 1])
        XCTAssertEqual(str.factorize(a + 2 * b), [1, 2])
    }
    
/* TODO
    func testFreeSub2() {
        let basis = (0 ..< 3).map{ A($0) }
        let a = M(basis: basis, components: [2, 0, 0])
        let b = M(basis: basis, components: [0, 4, 0])
        
        let str = S(generators: [a, b])
        
        XCTAssertEqual(str.rank, 2)
        XCTAssertEqual(str.factorize(a), [1, 0])
        XCTAssertEqual(str.factorize(b), [0, 1])
    }
 */
    
    func testDiagonalRelation() {
        let basis = (0 ..< 3).map{ M.wrap(A($0)) }
        let (e0, e1, e2) = (basis[0], basis[1], basis[2])
        
        let matrix = Matrix<R>(rows: 3, cols: 2, grid:
            [1, 0,
             0, 2,
             0, 0]
        )
        
        let str = S(generators: basis, relationMatrix: matrix)
        
        XCTAssertEqual(str.rank, 1)
        XCTAssertEqual(str.torsionCoeffs, [2])
        
        XCTAssertEqual(str.generator(0), e1)
        XCTAssertEqual(str.generator(1), e2)
        
        XCTAssertEqual(str.factorize(e0), [0, 0])
        XCTAssertEqual(str.factorize(e1), [1, 0])
        XCTAssertEqual(str.factorize(2 * e1), [0, 0])
        XCTAssertEqual(str.factorize(e2), [0, 1])
        XCTAssertEqual(str.factorize(2 * e2), [0, 2])
    }
    
    func testCrossRelation() {
        let basis = (0 ..< 3).map{ M.wrap(A($0)) }
        let (e0, e1, e2) = (basis[0], basis[1], basis[2])

        let matrix = Matrix<R>(rows: 3, cols: 2, grid:
            [1, 1,
             1, 0,
             0, -1]
        )
        let str = S(generators: basis, relationMatrix: matrix)
        
        XCTAssertEqual(str.rank, 1)
        XCTAssertEqual(str.generator(0), e2)
        
        XCTAssertEqual(str.factorize(e0), [1])
        XCTAssertEqual(str.factorize(e1), [-1])
        XCTAssertEqual(str.factorize(e2), [1])
    }
    
    func testSubsummands() {
        let basis = (0 ..< 3).map{ M.wrap(A($0)) }
        let (e0, e1, e2) = (basis[0], basis[1], basis[2])
        let matrix = Matrix<R>(rows: 3, cols: 2, grid:[2, 0, 0, 4, 0, 0])
        
        let str = S(generators: basis, relationMatrix: matrix)
        let sub0 = str.subSummands(0)
        let sub1 = str.subSummands(1)
        let sub2 = str.subSummands(2)
        
        XCTAssertEqual(sub0.generator(0), e0)
        XCTAssertEqual(sub0.torsionCoeffs, [2])
        XCTAssertEqual(sub0.factorize(e0), [1])
        
        XCTAssertEqual(sub1.generator(0), e1)
        XCTAssertEqual(sub1.torsionCoeffs, [4])
        XCTAssertEqual(sub1.factorize(e1), [1])
        
        XCTAssertEqual(sub2.generator(0), e2)
        XCTAssertTrue (sub2.isFree)
        XCTAssertEqual(sub2.factorize(e2), [1])
    }
    
    func testDirSum1() {
        let basis = (0 ..< 3).map{ M.wrap(A($0)) }
        let (e0, e1, e2) = (basis[0], basis[1], basis[2])
        let matrix = Matrix<R>(rows: 3, cols: 2, grid:[2, 0, 0, 4, 0, 0])
        
        let str = S(generators: basis, relationMatrix: matrix)
        let sub0 = str.subSummands(0)
        let sub2 = str.subSummands(2)
        
        let sum = sub0 ⊕ sub2
        
        XCTAssertEqual(sum.structure, [0: 1, 2: 1])
        XCTAssertEqual(sum[0].generator, e0)
        XCTAssertEqual(sum[1].generator, e2)
        
        XCTAssertEqual(sum.factorize(e0 + e2), [1, 1])
        XCTAssertEqual(sum.factorize(2 * e0), [0, 0])
        XCTAssertEqual(sum.factorize(2 * e2), [0, 2])
        
        XCTAssertTrue(!sum.contains(e1))
    }
    
    func testDirSum2() {
        let basis = (0 ..< 3).map{ M.wrap(A($0)) }
        let (e0, e1, e2) = (basis[0], basis[1], basis[2])

        let sub0 = S(generators: [e0], relationMatrix: Matrix<R>(rows: 1, cols: 1, grid:[2]))
        let sub2 = S(basis: [e2])
        let sum = sub0 ⊕ sub2
        
        XCTAssertEqual(sum.structure, [0: 1, 2: 1])
        XCTAssertEqual(sum[0].generator, e0)
        XCTAssertEqual(sum[1].generator, e2)
        
        XCTAssertEqual(sum.factorize(e0 + e2), [1, 1])
        XCTAssertEqual(sum.factorize(2 * e0), [0, 0])
        XCTAssertEqual(sum.factorize(2 * e2), [0, 2])
        
        XCTAssertTrue(!sum.contains(e1))
    }
    
    func testAbstract() {
        let str = S(rank: 1, torsions: [2, 3])
        XCTAssertEqual(str.rank, 1)
        XCTAssertEqual(str.torsionCoeffs, [2, 3])
    }
}
