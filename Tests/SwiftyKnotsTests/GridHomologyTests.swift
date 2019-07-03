//
//  GridHomologyTests.swift
//  SwiftyKnotsTests
//
//  Created by Taketo Sano on 2019/07/01.
//

import XCTest
@testable import SwiftyKnots

class GridHomologyTests: XCTestCase {

    func testTrefoil() {
        let G = GridDiagram(arcPresentation: 5,2,1,3,2,4,3,5,4,1)
        G.printDiagram()
    }
}
