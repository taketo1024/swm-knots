//
//  KhHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath
import SwiftyHomology

public struct KhovanovHomology<R: EuclideanRing> {
    public let cube: KhCube<R>
    private let homology: Homology2<FreeModule<KhEnhancedState, R>>
    public let normalized: Bool
    
    internal init(cube: KhCube<R>, homology: Homology2<FreeModule<KhEnhancedState, R>>, normalized: Bool) {
        self.cube = cube
        self.homology = homology
        self.normalized = normalized
    }
    
    public init(link L: Link, type: R.Type, normalized: Bool = true) {
        let (n⁺, n⁻) = (L.crossingNumber⁺, L.crossingNumber⁻)
        let cube = KhCube<R>(link: L)
        let chainCpx = cube.fold()
        let bigraded = ChainComplex2(grid: ModuleGrid { I in
            let (i, j) = (I[0], I[1])
            let Ci = chainCpx[i]
            let gens = Ci.generators.compactMap{ e -> KhEnhancedState? in
                let x = e.decomposed()[0].0
                return (x.degree == j) ? x : nil
            }
            return ModuleObject(basis: gens)
        }, differential: ChainMap2(multiDegree: [1, 0]) { I in
            chainCpx.differential[I[0]]
        }).shifted(normalized ? [-n⁻, n⁺ - 2 * n⁻] : [0, 0])
        
        self.init(cube: cube, homology: bigraded.homology, normalized: normalized)
    }
    
    public subscript(i: Int, j: Int) -> ModuleObject<FreeModule<KhEnhancedState, R>> {
        return homology[i, j]
    }
    
    public var link: Link {
        return cube.link
    }
    
    public var supportedArea: (ClosedRange<Int>, ClosedRange<Int>) {
        let L = link
        let (n, n⁺, n⁻) = (L.crossingNumber, L.crossingNumber⁺, L.crossingNumber⁻)
        let (range1, range2): (ClosedRange<Int>, ClosedRange<Int>)
        
        if normalized {
            let qShift = n⁺ - 2 * n⁻
            range1 = (-n⁻ ... n⁺)
            range2 = (cube.startVertex.generators.map{ $0.degree + qShift }.min()! ... cube.endVertex.generators.map{ $0.degree + qShift }.max()!)
        } else {
            range1 = (0 ... n)
            range2 = (cube.startVertex.generators.map{ $0.degree }.min()! ... cube.endVertex.generators.map{ $0.degree }.max()!)
        }
        
        return (range1, range2)
    }
    
    public func printTable() {
        let l = link.components.count
        let (r1, r2) = supportedArea
        homology.grid.printTable(indices1: r1.toArray(), indices2: r2.filter{ ($0 - l) % 2 == 0 })
    }
    
    public var gradedEulerCharacteristic: LaurentPolynomial<_q, 𝐙> {
        typealias P = LaurentPolynomial<_q, 𝐙>
        let q = P.indeterminate
        let (I, J) = supportedArea
        
        return I.sum{ i -> P in
            P((-1).pow(i)) * J.sum { j -> P in
                P(self[i, j].rank) * q.pow(j)
            }
        }
    }
}

extension Link {
    public func KhovanovHomology<R: EuclideanRing>(_ type: R.Type, normalized: Bool = true) -> KhovanovHomology<R> {
        return SwiftyKnots.KhovanovHomology(link: self, type: type, normalized: normalized)
    }
    
    public func parameterizedKhovanovHomology<R: EuclideanRing>(_ type: R.Type, h: R, t: R, normalized: Bool = true) -> Homology1<FreeModule<KhEnhancedState, R>> {
        let n⁻ = crossingNumber⁻
        let cube = KhCube<R>(link: self, h: h, t: t)
        let chainComplex = cube.fold().shifted(normalized ? -n⁻ : 0)
        return chainComplex.homology
    }
    
    public func LeeHomology<R: EuclideanRing>(_ type: R.Type, normalized: Bool = true) -> Homology1<FreeModule<KhEnhancedState, R>> {
        return parameterizedKhovanovHomology(R.self, h: .zero, t: .identity, normalized: normalized)
    }

    public func BarNatanHomology<R: EuclideanRing>(_ type: R.Type, normalized: Bool = true) -> Homology1<FreeModule<KhEnhancedState, R>> {
        return parameterizedKhovanovHomology(R.self, h: .identity, t: .zero, normalized: normalized)
    }
}
