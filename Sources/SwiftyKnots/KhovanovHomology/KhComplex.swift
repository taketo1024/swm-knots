//
//  KhComplex.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/10/10.
//

import SwiftyMath
import SwiftyHomology

public typealias KhovanovComplex<R: Ring> = ChainComplex1<LinearCombination<KhComplexGenerator, R>>
public typealias BigradedKhovanovComplex<R: Ring> = ChainComplex2<LinearCombination<KhComplexGenerator, R>>

public enum KhovanovComplexType {
    case Khovanov, Lee, BarNatan
}

extension KhCube {
    func differential<BaseModule: FreeModule>(at i: Int) -> ModuleEnd<BaseModule> where BaseModule.Generator == KhComplexGenerator, BaseModule.BaseRing == R {
        .linearlyExtend { x in
            let v = self[x.state]
            return v.targetStates.sum { (ε, target) in
                let f = self.edgeMap(from: x.state, to: target)
                return BaseModule( ε * f.applied(to: x) )
            }
        }
    }
}

// SinglyGraded
extension ChainComplex where GridDim == _1, BaseModule: FreeModule, BaseModule.Generator == KhComplexGenerator {
    public init(type: KhovanovComplexType = .Khovanov, link L: Link, normalized: Bool = true) {
        let (h, t): (R, R)
        switch type {
        case .Khovanov: (h, t) = (.zero, .zero)
        case .Lee:      (h, t) = (.zero, .identity)
        case .BarNatan: (h, t) = (.identity, .zero)
        }
        self.init(link: L, h: h, t: t, normalized: normalized)
    }
    
    public init(link L: Link, h: R, t: R, normalized: Bool = true) {
        let cube = KhCube(link: L, h: h, t: t)
        self.init(link: L, cube: cube, normalized: normalized)
    }
    
    public init(link L: Link, cube: KhCube<R>, normalized: Bool = true) {
        let (n, n⁻) = (L.crossingNumber, L.crossingNumber⁻)
        let s = normalized ? n⁻ : 0
        
        self.init(
            type: .ascending,
            support: -s ... n - s,
            sequence: { i in
                guard (-s ... n - s).contains(i) else {
                    return .zeroModule
                }
                
                let states = cube.states(ofDegree: i + s)
                let generators = states.flatMap{ cube[$0].generators }
                return ModuleObject(basis: generators)
            },
            differential: { i in
                cube.differential(at: i)
            }
        )
    }
}

// Bigraded
extension ChainComplex where GridDim == _2, BaseModule: FreeModule, BaseModule.Generator == KhComplexGenerator {
    public init(link L: Link, normalized: Bool = true) {
        self.init(link: L, h: .zero, t: .zero, normalized: normalized)
    }
    
    public init(link L: Link, h: R, t: R, normalized: Bool = true) {
        assert(h.isZero || h.degree == -2)
        assert(t.isZero || t.degree == -4)
        
        let cube = KhCube(link: L, h: h, t: t)
        self.init(link: L, cube: cube, normalized: normalized)
    }
        
    public init(link L: Link, cube: KhCube<R>, normalized: Bool = true) {
        let (n, n⁺, n⁻) = (L.crossingNumber, L.crossingNumber⁺, L.crossingNumber⁻)
        let (s1, s2) = normalized ? (n⁻, 2 * n⁻ - n⁺) : (0, 0)
        
        let (qmin, qmax) = (cube.startVertex.minQdegree, cube.endVertex.maxQdegree)
        let supp: ClosedRange<Coords> = [-s1, qmin - s2] ... [n - s1, qmax - s2]

        self.init(
            grid: ModuleGrid2(support: supp) { I in
                let (i, j) = (I[0], I[1])
                guard (-s1 ... n - s1).contains(i) else {
                    return .zeroModule
                }
                
                let states = cube.states(ofDegree: i + s1)
                let generators = states.flatMap{ s in cube[s].generators.filter{ x in x.degree == j + s2 } }
                return ModuleObject(basis: generators)
            },
            differential: ChainMap2(multiDegree: [1, 0]) { I in
                cube.differential(at: I[0])
            }
        )
    }
}

public func KhovanovHomology<R: EuclideanRing>(_ L: Link, _ type: R.Type, normalized: Bool = true) -> ModuleGrid2<LinearCombination<KhComplexGenerator, R>> {
    BigradedKhovanovComplex(link: L, normalized: normalized).homology
}

public func LeeHomology<R: EuclideanRing>(_ L: Link, _ type: R.Type, normalized: Bool = true) -> ModuleGrid1<LinearCombination<KhComplexGenerator, R>> {
    KhovanovComplex(type: .Lee, link: L, normalized: normalized).homology
}

public func BarNatanHomology<R: EuclideanRing>(_ L: Link, _ type: R.Type, normalized: Bool = true) -> ModuleGrid1<LinearCombination<KhComplexGenerator, R>> {
    KhovanovComplex(type: .BarNatan, link: L, normalized: normalized).homology
}

extension ModuleGrid where GridDim == _2 {
    // Σ_{i, j} (-1)^i q^j rank(H[i, j])
    public var gradedEulerCharacteristic: LaurentPolynomial<_q, 𝐙> {
        guard let support = support else { return .zero }
        let (r1, r2) = support.range
        
        typealias P = LaurentPolynomial<_q, 𝐙>
        let q = P.indeterminate
        
        return (r1 * r2).sum { (i, j) -> P in
            P((-1).pow(i) * self[i, j].rank) * q.pow(j)
        }
    }
}
