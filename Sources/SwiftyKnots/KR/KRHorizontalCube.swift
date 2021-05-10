//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/10.
//

import SwiftyMath
import SwiftyHomology

internal struct KRHorizontalCube<R: Ring>: ModuleCube {
    typealias Grading = KRHomology<R>.Grading
    typealias EdgeRing = KRHomology<R>.EdgeRing
    typealias BaseModule = KRHomology<R>.BaseModule
    
    typealias Vertex = ModuleObject<BaseModule>
    typealias Edge = ModuleEnd<BaseModule>
    
    let L: Link
    let coords: Coords // Cubic coord in Cube2
    let slice: Int
    let connection: [Int : KRComplexBuilder<R>.EdgeConnection]
    
    init(link L: Link, coords: Coords, slice: Int, connection: [Int : KRComplexBuilder<R>.EdgeConnection]) {
        self.L = L
        self.coords = coords
        self.slice = slice
        self.connection = connection
    }
    
    var dim: Int {
        L.crossingNumber
    }
    
    var baseGrading: Grading {
        let v0 = Coords.zeros(length: dim)
        return gradingShift(at: v0)
    }
    
    func gradingShift(at subcoords: Coords) -> Grading {
        (0 ..< L.crossingNumber).sum { i -> Grading in
            switch (L.crossings[i].crossingSign, coords[i], subcoords[i]) {
            case (+1, 0, 0):
                return [2, -2, -2]
            case (+1, 0, 1):
                return [0, 0, -2]
            case (+1, 1, 0):
                return [0, -2, 0]
            case (+1, 1, 1):
                return [0, 0, 0]
                
            case (-1, 0, 0):
                return [0, -2, 0]
            case (-1, 0, 1):
                return [0, 0, 0]
            case (-1, 1, 0):
                return [0, -2, 2]
            case (-1, 1, 1):
                return [-2, 0, 2]
                
            default:
                fatalError("impossible")
            }
        }
    }
    
    subscript(v: Coords) -> ModuleObject<BaseModule> {
        let q = slice + v.weight + (baseGrading - gradingShift(at: v))[0] / 2
        if q >= 0 {
            let mons = MultivariatePolynomialGenerator<_xn>.monomials(
                ofTotalExponent: q,
                usingIndeterminates: (0 ..< dim).toArray()
            )
            return ModuleObject(basis: mons)
        } else {
            return .zeroModule
        }
    }
    
    private func edgeFactor(from: Coords, to: Coords) -> EdgeRing {
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
        
        switch (L.crossings[p].crossingSign, coords[p]) {
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
        return .linearlyExtend { x -> BaseModule in
            (EdgeRing.wrap(x) * p).asLinearCombination
        }
    }
}

// TODO to be moved to SwiftyHomology
extension GridCoords: AdditiveGroup {
    public var dim: Int {
        GridDim.intValue
    }
    
    public static var zero: GridCoords<GridDim> {
        Self([0] * GridDim.intValue)
    }
    
    public var description: String {
        "(" + (0 ..< GridDim.intValue).map{ i in self[i].description }.joined(separator: ", ") + ")"
    }
}
