//
//  SwiftyAlgebraTests.swift
//  SwiftyAlgebraTests
//
//  Created by Taketo Sano on 2017/05/03.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import XCTest
@testable import SwiftyAlgebra

internal typealias Z = IntegerNumber
internal typealias Q = RationalNumber
internal typealias R = RealNumber

class SwiftyAlgebraTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        typealias M = Matrix<Z,_2,_2>
        let A = M(1, 2,
                  0, 3)
        
        var I = MatrixIterator(A, direction: .Cols, nonZeroOnly: true)
        while let a = I.next() {
            print(a)
        }
        

//        let C = SimplicialComplex.torus(dim: 4)
//        let H = Homology(C, Z.self)
//        print("H(T^4; Z) =", H.detailDescription, "\n")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
