//
//  GridHomologyTests.swift
//  SwiftyKnotsTests
//
//  Created by Taketo Sano on 2019/07/01.
//

import XCTest
import SwiftyMath
import SwiftyHomology
@testable import SwiftyKnots

class GridHomologyTests: XCTestCase {
    
    override func setUp() {
        try! Link.loadTable("K10")
    }
    
    override func tearDown() {
        Link.unloadTable()
    }
    
    func testChainComplex_tilde() {
        let G = GridDiagram.load("0_1")!
        let C = GridComplex(type: .tilde, diagram: G)
        XCTAssertEqual(C[1].rank, 0)
        XCTAssertEqual(C[0].rank, 1)
        XCTAssertEqual(C[-1].rank, 1)
        XCTAssertEqual(C[-2].rank, 0)
        XCTAssertEqual(C[-3].rank, 0)
    }
    
    func testChainComplex_hat() {
        let G = GridDiagram.load("0_1")!
        let C = GridComplex(type: .hat, diagram: G)
        XCTAssertEqual(C[1].rank, 0)
        XCTAssertEqual(C[0].rank, 1)
        XCTAssertEqual(C[-1].rank, 1)
        XCTAssertEqual(C[-2].rank, 1)
        XCTAssertEqual(C[-3].rank, 1)
        XCTAssertEqual(C[-4].rank, 1)
        XCTAssertEqual(C[-5].rank, 1)
    }
    
    func testChainComplex_minus() {
        let G = GridDiagram.load("0_1")!
        let C = GridComplex(type: .minus, diagram: G)
        XCTAssertEqual(C[1].rank, 0)
        XCTAssertEqual(C[0].rank, 1)
        XCTAssertEqual(C[-1].rank, 1)
        XCTAssertEqual(C[-2].rank, 2)
        XCTAssertEqual(C[-3].rank, 2)
        XCTAssertEqual(C[-4].rank, 3)
        XCTAssertEqual(C[-5].rank, 3)
    }
    
    func testKnotGenus0_1() {
        let G = GridDiagram.load("0_1")!
        XCTAssertEqual(GridComplex.genus(of: G), 0)
    }
    
    func testKnotGenus3_1() {
        let G = GridDiagram.load("3_1")!
        XCTAssertEqual(GridComplex.genus(of: G), 1)
    }

    func testKnotGenus4_1() {
        let G = GridDiagram.load("4_1")!
        XCTAssertEqual(GridComplex.genus(of: G), 1)
    }

    func testKnotGenus5_1() {
        let G = GridDiagram.load("5_1")!
        XCTAssertEqual(GridComplex.genus(of: G), 2)
    }

    func testKnotGenus5_2() {
        let G = GridDiagram.load("5_2")!
        XCTAssertEqual(GridComplex.genus(of: G), 1)
    }
    
    // GC-tilde(unknot)
    func testUnknot_tilde() {
        let G = GridDiagram.load("0_1")!
        let C = GridComplex(type: .tilde, diagram: G)
        let H = C.homology()
        
        print()
        
        XCTAssertEqual(H[0].rank, 1)
        XCTAssertEqual(H[-1].rank, 1)
    }
    
    // GC-tilde(unknot')
    func testUnknot_twisted_tilde() {
        let G = GridDiagram(arcPresentation: 1,2,3,1,2,3)
        let C = GridComplex(type: .tilde, diagram: G)
        let H = C.homology()
        
        XCTAssertEqual(H[0].rank, 1)
        XCTAssertEqual(H[-1].dictionaryDescription, [0 : 2])
        XCTAssertEqual(H[-2].rank, 1)
    }
    
    // GC-hat(unknot) = F
    func testUnknot_hat() {
        let G = GridDiagram.load("0_1")!
        let C = GridComplex(type: .hat, diagram: G)
        let H = C.homology()
        
        XCTAssertEqual(H[ 0].rank, 1)
        XCTAssertEqual(H[-1].rank, 0)
        XCTAssertEqual(H[-2].rank, 0)
    }
    
    // GC-hat(unknot') = F
    func testUnknot_twisted_hat() {
        let G = GridDiagram(arcPresentation: 1,2,3,1,2,3)
        let C = GridComplex(type: .hat, diagram: G)
        let H = C.homology()
        
        XCTAssertEqual(H[ 0].rank, 1)
        XCTAssertEqual(H[-1].rank, 0)
        XCTAssertEqual(H[-2].rank, 0)
    }
    
    // GC^-(unknot) = F[U]
    func testUnknot_minus() {
        let G = GridDiagram.load("0_1")!
        let C = GridComplex(type: .minus, diagram: G)
        let H = C.homology()
        
        XCTAssertEqual(H[ 0].rank, 1)
        XCTAssertEqual(H[-1].rank, 0)
        XCTAssertEqual(H[-2].rank, 1)
    }
    
    // GC^-(unknot) = F[U]
    func testUnknot_twisted_minus() {
        let G = GridDiagram(arcPresentation: 1,2,3,1,2,3)
        let C = GridComplex(type: .minus, diagram: G)
        let H = C.homology()
        
        XCTAssertEqual(H[ 0].rank, 1)
        XCTAssertEqual(H[-1].rank, 0)
        XCTAssertEqual(H[-2].rank, 1)
    }
    
    func testTrefoil_minus() {
        let G = GridDiagram.load("3_1")!
        let C = GridComplex(type: .minus, diagram: G)
        let H = C.homology()
        
        XCTAssertEqual(H[ 2].rank, 0)
        XCTAssertEqual(H[ 1].rank, 0)
        XCTAssertEqual(H[ 0].rank, 1)
        XCTAssertEqual(H[-1].rank, 0)
        XCTAssertEqual(H[-2].rank, 1)
    }

    func testTrefoil_mirror_minus() {
        let G = GridDiagram.load("3_1")!.rotate90
        let C = GridComplex(type: .minus, diagram: G)
        let H = C.homology()
        
        XCTAssertEqual(H[ 2].rank, 1)
        XCTAssertEqual(H[ 1].rank, 1)
        XCTAssertEqual(H[ 0].rank, 1)
        XCTAssertEqual(H[-1].rank, 0)
        XCTAssertEqual(H[-2].rank, 1)
    }
    
    func testTrefoil_filtered() {
        let G = GridDiagram.load("3_1")!
        let C = GridComplex(type: .filtered, diagram: G)
        let H = C.homology()
        
        XCTAssertEqual(H[ 2].rank, 0)
        XCTAssertEqual(H[ 1].rank, 0)
        XCTAssertEqual(H[ 0].rank, 1)
        XCTAssertEqual(H[-1].rank, 0)
        XCTAssertEqual(H[-2].rank, 1)
    }
    
    func testTrefoil_mirror_filtered() {
        let G = GridDiagram.load("3_1")!.rotate90
        let C = GridComplex(type: .filtered, diagram: G)
        let H = C.homology()
        
        XCTAssertEqual(H[ 2].rank, 0)
        XCTAssertEqual(H[ 1].rank, 0)
        XCTAssertEqual(H[ 0].rank, 1)
        XCTAssertEqual(H[-1].rank, 0)
        XCTAssertEqual(H[-2].rank, 1)
    }
}
