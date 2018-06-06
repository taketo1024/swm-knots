//
//  KhHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath
import SwiftyHomology

public extension Link {
    internal func KhCube<R>(_ μ: @escaping KhBasisElement.Product<R>, _ Δ: @escaping KhBasisElement.Coproduct<R>) -> ModuleCube<KhBasisElement, R> {
        typealias A = KhBasisElement
        
        let n = self.crossingNumber
        let states = self.allStates
        let Ls = Dictionary(keys: states){ s in self.spliced(by: s) }
        
        let objects = Dictionary(keys: states){ s -> ModuleObject<A, R> in
            let r = Ls[s]!.components.count
            let basis = A.generateBasis(state: s, power: r)
            return ModuleObject(generators: basis)
        }
        
        let edgeMaps = { (s0: IntList, s1: IntList) -> FreeModuleHom<A, A, R> in
            let (L0, L1) = (Ls[s0]!, Ls[s1]!)
            let (c1, c2) = (L0.components, L1.components)
            let (d1, d2) = (c1.filter{ !c2.contains($0) }, c2.filter{ !c1.contains($0) })
            switch (d1.count, d2.count) {
            case (2, 1):
                let (i1, i2) = (c1.index(of: d1[0])!, c1.index(of: d1[1])!)
                let j = c2.index(of: d2[0])!
                return FreeModuleHom{ (x: A) in x.applied(μ, at: (i1, i2), to: j, state: s1) }
                
            case (1, 2):
                let i = c1.index(of: d1[0])!
                let (j1, j2) = (c2.index(of: d2[0])!, c2.index(of: d2[1])!)
                return FreeModuleHom{ (x: A) in x.applied(Δ, at: i, to: (j1, j2), state: s1) }

            default: fatalError()
            }
        }
        
        return ModuleCube(dim: n, objects: objects, edgeMaps: edgeMaps)
    }
    
    public func KhChainComplex<R: EuclideanRing>(_ type: R.Type, reduced: Bool = false, normalized: Bool = true) -> ChainComplex2<KhBasisElement, R> {
        
        let name = "CKh(\(self.name); \(R.symbol))"
        let (n⁺, n⁻) = (crossingNumber⁺, crossingNumber⁻)
        
        let (μ, Δ) = (KhBasisElement.μ(R.self), KhBasisElement.Δ(R.self))
        let cube = self.KhCube(μ, Δ)
        
        let j0 = cube.bottom.generators.map{ $0.degree }.min() ?? 0
        let j1 =    cube.top.generators.map{ $0.degree }.max() ?? 0
        let js = (j0 ... j1).filter{ j in (j - j0) % 2 == 0 }
        
        let subcubes = Dictionary(keys: js) { j in
            cube.subCube{ s in s.generator.degree == j }
        }
        
        typealias Object = ModuleObject<KhBasisElement, R>
        let list = js.flatMap{ j -> [(Int, Int, Object?)] in
            let c = subcubes[j]!.asChainComplex()
            return c.degrees.map{ i in (i, j, c[i]) }
        }
        
        let base = ModuleGrid2(name: name, list: list, default: .zeroModule)
        let d = ChainMap2(bidegree: (1, 0)) { (i, j) -> FreeModuleHom<KhBasisElement, KhBasisElement, R> in
            guard let c = subcubes[j] else {
                return .zero
            }
            return FreeModuleHom{ (x: KhBasisElement) in
                c.d(from: x.state).applied(to: x)
            }
        }
        
        let CKh = ChainComplex2(base: base, differential: d)
        return normalized ? CKh.shifted(-n⁻, n⁺ - 2 * n⁻) : CKh
    }
    
    public func KhHomology<R: EuclideanRing>(_ type: R.Type, reduced: Bool = false, normalized: Bool = true) -> ModuleGrid2<KhBasisElement, R> {
        let name = "Kh(\(self.name); \(R.symbol))"
        let C = self.KhChainComplex(R.self, reduced: reduced, normalized: normalized)
        return C.homology(name: name)
    }
    
    public func KhHomology<R: EuclideanRing & Codable>(_ type: R.Type, useCache: Bool) -> ModuleGrid2<KhBasisElement, R> {
        if useCache {
            let id = "Kh_\(name)_\(R.symbol)"
            return Storage.useCache(id) { KhHomology(R.self) }
        } else {
            return KhHomology(R.self)
        }
    }
    
    /*
    public func KhLeeChainComplex<R: EuclideanRing>(_ type: R.Type) -> ChainComplex2<KhBasisElement, R> {
        typealias C = ChainComplex2<KhBasisElement, R>
        let base = KhHomology(type)
        let d = ChainMap2(bidegree: (1, 4)) { (_, _) in self.KhCube.d_Lee(R.self) }
        return ChainComplex2(base: base, differential: d)
    }

    public func KhLeeHomology<R: EuclideanRing>(_ type: R.Type) -> ModuleGrid2<KhBasisElement, R> {
        let name = "KhLee(\(self.name); \(R.symbol))"
        return KhLeeChainComplex(type).homology(name: name)
    }
 */
}

public extension GridN where n == _2, Object: _ModuleObject, Object.A == KhBasisElement {
    public var bandWidth: Int {
        return bidegrees.map{ (i, j) in j - 2 * i }.unique().count
    }
    
    public var isDiagonal: Bool {
        return bandWidth == 1
    }
    
    public var isHThin: Bool {
        return bandWidth <= 2
    }
    
    public var isHThick: Bool {
        return !isHThin
    }
    
    public var qEulerCharacteristic: LaurentPolynomial<R, JonesPolynomial_q> {
        let q = LaurentPolynomial<R, JonesPolynomial_q>.indeterminate
        return bidegrees.sum { (i, j) -> LaurentPolynomial<R, JonesPolynomial_q> in
            let s = self[i, j]!
            let a = R(from: (-1).pow(i) * s.entity.rank )
            return a * q.pow(j)
        }
    }
}
