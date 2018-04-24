//
//  SimpleModuleStructureTests.swift
//  SwiftyMathTests
//
//  Created by Taketo Sano on 2018/04/23.
//

import XCTest
@testable import SwiftyMath

class SimpleModuleStructureTests: XCTestCase {
    
    typealias A = AbstractBasisElement
    typealias R = 𝐙
    typealias M = FreeModule<A, R>
    typealias S = SimpleModuleStructure<A, R>

    func testFree() {
        let basis = (0 ..< 3).map{ A($0) }
        let matrix = ComputationalMatrix<R>.zero(rows: 3, cols: 0)
        let str = SimpleModuleStructure<A, R>(generators: basis, relationMatrix: matrix)
        XCTAssertEqual(str.rank, 3)
    }
    
    func testRelation() {
        typealias A = AbstractBasisElement
        let basis = (0 ..< 3).map{ A($0) }
        let matrix = ComputationalMatrix<R>(rows: 3, cols: 2, grid:[1, 0, 0, 2, 0, 0])
        let str = S(generators: basis, relationMatrix: matrix)
        XCTAssertEqual(str.rank, 1)
        XCTAssertEqual(str.torsionCoeffs, [2])
        XCTAssertEqual(str.generator(0), M(basis[1]))
        XCTAssertEqual(str.generator(1), M(basis[2]))
    }
    
    func testFactorize() {
        typealias A = AbstractBasisElement
        let basis = (0 ..< 3).map{ A($0) }
        let matrix = ComputationalMatrix<R>(rows: 3, cols: 2, grid:[1, 0, 0, 2, 0, 0])
        let str = S(generators: basis, relationMatrix: matrix)
        
        let z1 = M(basis: basis, components: [1, 0, 0])
        let z2 = M(basis: basis, components: [0, 1, 0])
        let z3 = M(basis: basis, components: [0, 0, 1])

        XCTAssertEqual(str.factorize(z1), [0, 0])
        XCTAssertEqual(str.factorize(z2), [1, 0])
        XCTAssertEqual(str.factorize(z3), [0, 1])
        XCTAssertEqual(str.factorize(2 * z2 - z3), [0, -1])
    }
}
