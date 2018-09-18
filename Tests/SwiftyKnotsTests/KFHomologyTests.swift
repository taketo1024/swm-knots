//
//  KFHomologyTests.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/28.
//

import XCTest
@testable import SwiftyMath
@testable import SwiftyKnots

class KFHomologyTests: XCTestCase {
    func testTrefoil() {
        let G = GridDiagram(OX: (0, 1), (2, 1), (2, 3), (4, 3), (4, 0), (1, 0), (1, 2), (3, 2), (3, 4), (0, 4))
        G.printDiagram()
    }
    
    func testFigure8() {
        let G = GridDiagram(OX: (0, 3), (2, 3), (2, 5), (5, 5), (5, 1), (3, 1), (3, 4), (1, 4), (1, 2), (4, 2), (4, 0), (0, 0))
        G.printDiagram()
    }
}
