//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/10.
//

import SwiftyMath
import SwiftyHomology

internal struct KRHorizontalCube<R: Ring>: ModuleCube {
    typealias BaseModule = KR.BaseModule<R>
    typealias Vertex = ModuleStructure<BaseModule>
    typealias Edge = ModuleEnd<BaseModule>

    let L: Link
    let vCoords: Coords // Cubic coord in Cube2
    let slice: Int
    let connection: [Int : KR.EdgeConnection<R>]
    
    init(link L: Link, vCoords: Coords, slice: Int, connection: [Int : KR.EdgeConnection<R>]) {
        self.L = L
        self.vCoords = vCoords
        self.slice = slice
        self.connection = connection
    }
    
    var dim: Int {
        L.crossingNumber
    }
    
    var baseGrading: KR.Grading {
        let v0 = Coords.zeros(length: dim)
        return KR.baseGrading(link: L, hCoords: v0, vCoords: v0)
    }
    
    func gradingShift(at hCoords: Coords) -> KR.Grading {
        KR.baseGrading(link: L, hCoords: hCoords, vCoords: vCoords)
    }
    
    subscript(v: Coords) -> ModuleStructure<BaseModule> {
        let deg = slice + v.weight + (baseGrading - gradingShift(at: v))[0] / 2
        if deg >= 0 {
            let mons = KR.EdgeRing<R>.monomials(
                ofDegree: 2 * deg,
                usingIndeterminates: 0 ..< dim
            ).map {
                BaseModule.Generator(exponent: $0.leadExponent)
            }
            return ModuleStructure<BaseModule>(rawGenerators: mons)
        } else {
            return .zeroModule
        }
    }
    
    private func edgeFactor(from: Coords, to: Coords) -> KR.EdgeRing<R> {
        if !(from < to) {
            return .zero
        }
        let e = (to - from).enumerated().filter{ (_, b) in b == 1 }
        if e.count > 1 {
            return .zero
        }
        
        let p = e.first!.offset
        let c = connection[p]!
        let (ik, il) = (c.ik, c.il)
        
        switch (L.crossings[p].crossingSign, vCoords[p]) {
        case (+1, 0), (-1, 1):
            return ik * il
        case (+1, 1), (-1, 0):
            return ik
        default:
            fatalError("impossible")
        }
    }
    
    func edge(from: Coords, to: Coords) -> ModuleEnd<BaseModule> {
        let p = edgeFactor(from: from, to: to)
        return .init { z -> BaseModule in
            let q = MultivariatePolynomial(z)
            return (p * q).asLinearCombination
        }
    }
}
