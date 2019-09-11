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
        let H = C.homology
        
        XCTAssertEqual(H[0].dictionaryDescription, [0 : 1])
        XCTAssertEqual(H[-1].dictionaryDescription, [0 : 1])
    }
    
    // GC-tilde(unknot')
    func testUnknot_twisted_tilde() {
        let G = GridDiagram(arcPresentation: 1,2,3,1,2,3)
        let C = GridComplex(type: .tilde, diagram: G)
        let H = C.homology
        
        XCTAssertEqual(H[0].dictionaryDescription, [0 : 1])
        XCTAssertEqual(H[-1].dictionaryDescription, [0 : 2])
        XCTAssertEqual(H[-2].dictionaryDescription, [0 : 1])
    }
    
    // GC-hat(unknot) = F
    func testUnknot_hat() {
        let G = GridDiagram.load("0_1")!
        let C = GridComplex(type: .hat, diagram: G)
        let H = C.homology
        
        XCTAssertEqual(H[ 0].dictionaryDescription, [0 : 1])
        XCTAssertEqual(H[-1].dictionaryDescription, [:])
        XCTAssertEqual(H[-2].dictionaryDescription, [:])
    }
    
    // GC-hat(unknot') = F
    func testUnknot_twisted_hat() {
        let G = GridDiagram(arcPresentation: 1,2,3,1,2,3)
        let C = GridComplex(type: .hat, diagram: G)
        let H = C.homology
        
        XCTAssertEqual(H[ 0].dictionaryDescription, [0 : 1])
        XCTAssertEqual(H[-1].dictionaryDescription, [:])
        XCTAssertEqual(H[-2].dictionaryDescription, [:])
    }
    
    // GC^-(unknot) = F[U]
    func testUnknot_minus() {
        let G = GridDiagram.load("0_1")!
        let C = GridComplex(type: .minus, diagram: G)
        let H = C.homology
        
        XCTAssertEqual(H[ 0].dictionaryDescription, [0 : 1])
        XCTAssertEqual(H[-1].dictionaryDescription, [:])
        XCTAssertEqual(H[-2].dictionaryDescription, [0 : 1])
    }
    
    // GC^-(unknot) = F[U]
    func testUnknot_twisted_minus() {
        let G = GridDiagram(arcPresentation: 1,2,3,1,2,3)
        let C = GridComplex(type: .minus, diagram: G)
        let H = C.homology
        
        XCTAssertEqual(H[ 0].dictionaryDescription, [0 : 1])
        XCTAssertEqual(H[-1].dictionaryDescription, [:])
        XCTAssertEqual(H[-2].dictionaryDescription, [0 : 1])
    }
    
    func testTrefoil_minus() {
        let G = GridDiagram.load("3_1")!
        let C = GridComplex(type: .minus, diagram: G)
        let H = C.homology
        
        XCTAssertEqual(H[ 2].dictionaryDescription, [:])
        XCTAssertEqual(H[ 1].dictionaryDescription, [:])
        XCTAssertEqual(H[ 0].dictionaryDescription, [0 : 1])
        XCTAssertEqual(H[-1].dictionaryDescription, [:])
        XCTAssertEqual(H[-2].dictionaryDescription, [0 : 1])
    }

    func testTrefoil_mirror_minus() {
        let G = GridDiagram.load("3_1")!.rotate90
        let C = GridComplex(type: .minus, diagram: G)
        let H = C.homology
        
        XCTAssertEqual(H[ 2].dictionaryDescription, [0 : 1])
        XCTAssertEqual(H[ 1].dictionaryDescription, [0 : 1])
        XCTAssertEqual(H[ 0].dictionaryDescription, [0 : 1])
        XCTAssertEqual(H[-1].dictionaryDescription, [:])
        XCTAssertEqual(H[-2].dictionaryDescription, [0 : 1])
    }
    
    func testTrefoil_filtered() {
        let G = GridDiagram.load("3_1")!
        let C = GridComplex(type: .filtered, diagram: G)
        let H = C.homology
        
        XCTAssertEqual(H[ 2].dictionaryDescription, [:])
        XCTAssertEqual(H[ 1].dictionaryDescription, [:])
        XCTAssertEqual(H[ 0].dictionaryDescription, [0 : 1])
        XCTAssertEqual(H[-1].dictionaryDescription, [:])
        XCTAssertEqual(H[-2].dictionaryDescription, [0 : 1])
    }
    
    func testTrefoil_mirror_filtered() {
        let G = GridDiagram.load("3_1")!.rotate90
        let C = GridComplex(type: .filtered, diagram: G)
        let H = C.homology
        
        XCTAssertEqual(H[ 2].dictionaryDescription, [:])
        XCTAssertEqual(H[ 1].dictionaryDescription, [:])
        XCTAssertEqual(H[ 0].dictionaryDescription, [0 : 1])
        XCTAssertEqual(H[-1].dictionaryDescription, [:])
        XCTAssertEqual(H[-2].dictionaryDescription, [0 : 1])
    }
}
