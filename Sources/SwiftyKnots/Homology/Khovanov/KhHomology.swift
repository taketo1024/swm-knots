//
//  KhHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath
import SwiftyHomology

private struct t4: Indeterminate {
    static var symbol = "t"
    static var degree = -4
}

public struct KhovanovChainComplex<R: Ring> {
    public let L: Link
    public let cube: ModuleCube<KhEnhancedState, R>
    public let chainComplex: ChainComplex<KhEnhancedState, R>
    public let normalized: Bool
    
    public subscript(_ i: Int) -> ModuleObject<KhEnhancedState, R> {
        return chainComplex[i]!
    }
    
    public init(_ L: Link, h: R = .zero, t: R = .zero, normalized: Bool = true) {
        let   product = KhEnhancedState.product  (R.self, h: h, t: t)
        let coproduct = KhEnhancedState.coproduct(R.self, h: h, t: t)
        self.init(L, product: product, coproduct: coproduct, normalized: normalized)
    }
    
    public init(_ L: Link, product: KhEnhancedState.Product<R>, coproduct: KhEnhancedState.Coproduct<R>, normalized: Bool = true) {
        let cube = KhovanovChainComplex<R>.cube(L, product: product, coproduct: coproduct)
        let chainComplex = { () -> ChainComplex<KhEnhancedState, R> in
            let name = "CKh(\(L.name)\( R.self == 𝐙.self ? "" : "; \(R.symbol)"))"
            let base = cube.fold().named(name).shifted(normalized ? -L.crossingNumber⁻ : 0)
            let d = ChainMap(degree: 1) { _ in
                ModuleHom.linearlyExtend{ x in
                    cube.d(x.state).applied(to: .wrap(x))
                }
            }
            return ChainComplex(base: base, differential: d)
        }()
        
        self.L = L
        self.cube = cube
        self.chainComplex = chainComplex
        self.normalized = normalized
    }
    
    public static func cube(_ L: Link, product: KhEnhancedState.Product<R>, coproduct: KhEnhancedState.Coproduct<R>) -> ModuleCube<KhEnhancedState, R> {
        typealias A = KhEnhancedState
        
        let n = L.crossingNumber
        let states = L.allStates
        let Ls = Dictionary(keys: states){ s in L.spliced(by: s) }
        
        let objects = Dictionary(keys: states){ s -> ModuleObject<A, R> in
            let comps = Ls[s]!.components
            let basis = A.generateBasis(state: s, power: comps.count)
            return ModuleObject(basis: basis)
        }
        
        let edgeMaps = { (s0: IntList, s1: IntList) -> ModuleCube<A, R>.EdgeMap in
            let (L0, L1) = (Ls[s0]!, Ls[s1]!)
            let (c1, c2) = (L0.components, L1.components)
            let (d1, d2) = (c1.filter{ !c2.contains($0) }, c2.filter{ !c1.contains($0) })
            switch (d1.count, d2.count) {
            case (2, 1):
                let (i1, i2) = (c1.firstIndex(of: d1[0])!, c1.firstIndex(of: d1[1])!)
                let j = c2.firstIndex(of: d2[0])!
                return ModuleHom.linearlyExtend{ x in
                    x.applied(product, at: (i1, i2), to: j, state: s1)
                }
                
            case (1, 2):
                let i = c1.firstIndex(of: d1[0])!
                let (j1, j2) = (c2.firstIndex(of: d2[0])!, c2.firstIndex(of: d2[1])!)
                return ModuleHom.linearlyExtend{ x in
                    x.applied(coproduct, at: i, to: (j1, j2), state: s1)
                }
                
            default: fatalError()
            }
        }
        
        return ModuleCube(dim: n, objects: objects, edgeMaps: edgeMaps)
    }
}

extension KhovanovChainComplex where R: EuclideanRing {
    public func homology(_ i: Int) -> ModuleObject<KhEnhancedState, R> {
        return chainComplex.homology(i)!
    }
    
    public func homology() -> ModuleGrid1<KhEnhancedState, R> {
        return chainComplex.homology()
    }
    
    public func bigradedHomology(name: String? = nil) -> ModuleGrid2<KhEnhancedState, R> {
        let s = normalized ? (L.crossingNumber⁺ - 2 * L.crossingNumber⁻) : 0
        let H = chainComplex.homology()
        let list = (H.bottomDegree ... H.topDegree).flatMap { i -> [(IntList, ModuleObject<KhEnhancedState, R>?)] in
            let Hi = H[i]!
            let js = Hi.generators.map { z in z.degree }.unique()
            return js.map { j in
                (IntList(i, normalized ? j + s : j), Hi.subSummands{ $0.degree == j } )
            }
        }
        let data = Dictionary(pairs: list)
        return ModuleGrid2<KhEnhancedState, R>(name: name, data: data)
    }
}

extension Link {
    public func KhovanovChainComplex<R: Ring>(_ type: R.Type, h: R = .zero, t: R = .zero, normalized: Bool = true) -> KhovanovChainComplex<R> {
        return SwiftyKnots.KhovanovChainComplex<R>(self, h: h, t: t, normalized: normalized)
    }
    
    public func KhovanovHomology<R: EuclideanRing>(_ type: R.Type, normalized: Bool = true) -> ModuleGrid2<KhEnhancedState, R> {
        let name = "Kh(\(self.name)\( R.self == 𝐙.self ? "" : "; \(R.symbol)"))"
        let C = self.KhovanovChainComplex(type, normalized: normalized)
        return C.bigradedHomology(name: name)
    }
    
    public func LeeHomology<R: EuclideanRing>(_ type: R.Type, normalized: Bool = true) -> ModuleGrid1<KhEnhancedState, R> {
        let name = "Lee(\(self.name)\( R.self == 𝐙.self ? "" : "; \(R.symbol)"))"
        let C = self.KhovanovChainComplex(type, h: .zero, t: .identity, normalized: normalized)
        return C.homology().named(name)
    }
    
    public func BarNatanHomology<R: EuclideanRing>(_ type: R.Type, normalized: Bool = true) -> ModuleGrid1<KhEnhancedState, R> {
        let name = "BN(\(self.name)\( R.self == 𝐙.self ? "" : "; \(R.symbol)"))"
        let C = self.KhovanovChainComplex(type, h: .identity, t: .zero, normalized: normalized)
        return C.homology().named(name)
    }
}

extension ModuleGridN where n == _2, A == KhEnhancedState {
    public var bandWidth: Int {
        return indices.map{ I in I[1] - 2 * I[0] }.unique().count
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
}
