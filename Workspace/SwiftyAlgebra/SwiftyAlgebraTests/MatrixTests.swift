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

class MatrixTests: XCTestCase {
    
    typealias M = Matrix<_2, _2, Z>
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
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
    
    public func testAddRow() {
        var a = M(1,2,3,4)
        a.addRow(at: 0, to: 1)
        XCTAssertEqual(a, M(1,2,4,6))
    }
    
    public func testAddRowWithMul() {
        var a = M(1,2,3,4)
        a.addRow(at: 0, to: 1, multipliedBy: 2)
        XCTAssertEqual(a, M(1,2,5,8))
    }
    
    public func testAddCol() {
        var a = M(1,2,3,4)
        a.addCol(at: 0, to: 1)
        XCTAssertEqual(a, M(1,3,3,7))
    }
    
    public func testAddColWithMul() {
        var a = M(1,2,3,4)
        a.addCol(at: 0, to: 1, multipliedBy: 2)
        XCTAssertEqual(a, M(1,4,3,10))
    }
    
    public func testMulRow() {
        var a = M(1,2,3,4)
        a.multiplyRow(at: 0, by: 2)
        XCTAssertEqual(a, M(2,4,3,4))
    }
    
    public func testMulCol() {
        var a = M(1,2,3,4)
        a.multiplyCol(at: 0, by: 2)
        XCTAssertEqual(a, M(2,2,6,4))
    }
    
    public func testSwapRows() {
        var a = M(1,2,3,4)
        a.swapRows(0, 1)
        XCTAssertEqual(a, M(3,4,1,2))
    }
    
    public func testSwapCols() {
        var a = M(1,2,3,4)
        a.swapCols(0, 1)
        XCTAssertEqual(a, M(2,1,4,3))
    }
}
