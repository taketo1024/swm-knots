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
    public let cube: ModuleCube<KhBasisElement, R>
    public let chainComplex: ChainComplex<KhBasisElement, R>
    public let normalized: Bool
    
    public subscript(_ i: Int) -> ModuleObject<KhBasisElement, R> {
        return chainComplex[i]!
    }
    
    public init(_ L: Link, h: R = .zero, t: R = .zero, normalized: Bool = true) {
        let   product = KhBasisElement.product  (R.self, h: h, t: t)
        let coproduct = KhBasisElement.coproduct(R.self, h: h, t: t)
        self.init(L, product: product, coproduct: coproduct, normalized: normalized)
    }
    
    public init(_ L: Link, product: KhBasisElement.Product<R>, coproduct: KhBasisElement.Coproduct<R>, normalized: Bool = true) {
        let cube = KhovanovChainComplex<R>.cube(L, product: product, coproduct: coproduct)
        let chainComplex = { () -> ChainComplex<KhBasisElement, R> in
            let name = "CKh(\(L.name)\( R.self == 𝐙.self ? "" : "; \(R.symbol)"))"
            let base = cube.fold().named(name).shifted(normalized ? -L.crossingNumber⁻ : 0)
            let d = ChainMap(degree: 1) { _ in
                FreeModuleHom{ (x: KhBasisElement) in
                    cube.d(x.state).applied(to: x)
                }
            }
            return ChainComplex(base: base, differential: d)
        }()
        
        self.L = L
        self.cube = cube
        self.chainComplex = chainComplex
        self.normalized = normalized
    }
    
    public static func cube(_ L: Link, product: KhBasisElement.Product<R>, coproduct: KhBasisElement.Coproduct<R>) -> ModuleCube<KhBasisElement, R> {
        typealias A = KhBasisElement
        
        let n = L.crossingNumber
        let states = L.allStates
        let Ls = Dictionary(keys: states){ s in L.spliced(by: s) }
        
        let objects = Dictionary(keys: states){ s -> ModuleObject<A, R> in
            let comps = Ls[s]!.components
            let basis = A.generateBasis(state: s, power: comps.count)
            return ModuleObject(basis: basis)
        }
        
        let edgeMaps = { (s0: IntList, s1: IntList) -> FreeModuleHom<A, A, R> in
            let (L0, L1) = (Ls[s0]!, Ls[s1]!)
            let (c1, c2) = (L0.components, L1.components)
            let (d1, d2) = (c1.filter{ !c2.contains($0) }, c2.filter{ !c1.contains($0) })
            switch (d1.count, d2.count) {
            case (2, 1):
                let (i1, i2) = (c1.index(of: d1[0])!, c1.index(of: d1[1])!)
                let j = c2.index(of: d2[0])!
                return FreeModuleHom{ (x: A) in x.applied(product, at: (i1, i2), to: j, state: s1) }
                
            case (1, 2):
                let i = c1.index(of: d1[0])!
                let (j1, j2) = (c2.index(of: d2[0])!, c2.index(of: d2[1])!)
                return FreeModuleHom{ (x: A) in x.applied(coproduct, at: i, to: (j1, j2), state: s1) }
                
            default: fatalError()
            }
        }
        
        return ModuleCube(dim: n, objects: objects, edgeMaps: edgeMaps)
    }
}

public extension KhovanovChainComplex where R: EuclideanRing {
    public func homology(_ i: Int) -> ModuleObject<KhBasisElement, R> {
        return chainComplex.homology(i)!
    }
    
    public func homology() -> ModuleGrid1<KhBasisElement, R> {
        return chainComplex.homology()
    }
    
    public func bigradedHomology(name: String? = nil) -> ModuleGrid2<KhBasisElement, R> {
        let s = normalized ? (L.crossingNumber⁺ - 2 * L.crossingNumber⁻) : 0
        let H = chainComplex.homology()
        let list = (H.bottomDegree ... H.topDegree).flatMap { i -> [(IntList, ModuleObject<KhBasisElement, R>?)] in
            let Hi = H[i]!
            let js = Hi.generators.map { z in z.degree }.unique()
            return js.map { j in
                (IntList(i, normalized ? j + s : j), Hi.subSummands{ $0.degree == j } )
            }
        }
        let data = Dictionary(pairs: list)
        return ModuleGrid2<KhBasisElement, R>(name: name, data: data)
    }
}

public extension Link {
    @available(*, deprecated)
    public func KhChainComplex<R: Ring>(_ type: R.Type, normalized: Bool = true) -> KhovanovChainComplex<R> {
        return self.KhovanovChainComplex(type, normalized: normalized)
    }
    
    @available(*, deprecated)
    public func KhHomology<R: EuclideanRing>(_ type: R.Type, normalized: Bool = true) -> ModuleGrid2<KhBasisElement, R> {
        return self.KhovanovHomology(type, normalized: normalized)
    }
    
    public func KhovanovChainComplex<R: Ring>(_ type: R.Type, h: R = .zero, t: R = .zero, normalized: Bool = true) -> KhovanovChainComplex<R> {
        return SwiftyKnots.KhovanovChainComplex<R>(self, h: h, t: t, normalized: normalized)
    }
    
    public func KhovanovHomology<R: EuclideanRing>(_ type: R.Type, normalized: Bool = true) -> ModuleGrid2<KhBasisElement, R> {
        let name = "Kh(\(self.name)\( R.self == 𝐙.self ? "" : "; \(R.symbol)"))"
        let C = self.KhovanovChainComplex(type, normalized: normalized)
        return C.bigradedHomology(name: name)
    }
    
    public func LeeHomology<R: EuclideanRing>(_ type: R.Type, normalized: Bool = true) -> ModuleGrid1<KhBasisElement, R> {
        let name = "Lee(\(self.name)\( R.self == 𝐙.self ? "" : "; \(R.symbol)"))"
        let C = self.KhovanovChainComplex(type, h: .zero, t: .identity, normalized: normalized)
        return C.homology().named(name)
    }
    
    public func BarNatanHomology<R: EuclideanRing>(_ type: R.Type, normalized: Bool = true) -> ModuleGrid1<KhBasisElement, R> {
        let name = "BN(\(self.name)\( R.self == 𝐙.self ? "" : "; \(R.symbol)"))"
        let C = self.KhovanovChainComplex(type, h: .identity, t: .zero, normalized: normalized)
        return C.homology().named(name)
    }
    
    public var RasmussenInvariant: Int {
        return RasmussenInvariant(𝐐.self)
    }
    
    public func RasmussenInvariant<F: Field>(_ type: F.Type, forceCompute: Bool = false) -> Int {
        if !forceCompute, F.self == 𝐐.self, let s = Link.loadRasmussenInvariant(self.name) {
            return s
        }
        
        assert(components.count == 1) // currently supports only knots.
        
        typealias R = Polynomial<F, t4> // R = F[t], deg(t) = -4.
        
        let L = self
        let H0 = L.KhovanovChainComplex(R.self, h: .zero, t: R.indeterminate).homology(0).freePart
        let q = H0.generators.map { z in
            z.basis.map { x in x.qDegree(in: L) }.min()!
        }.max()!

        return q - 1
    }
    
    public var orientationPreservingState: IntList {
        return IntList(crossings.map{ $0.crossingSign == 1 ? 0 : 1 })
    }
    
    public func LeeCycles<R: Ring>(_ type: R.Type, _ c: R) -> [FreeModule<KhBasisElement, R>] {
        return LeeCycles(R.self, .zero, c)
    }
    
    public func LeeCycles<R: Ring>(_ type: R.Type, _ u: R, _ v: R) -> [FreeModule<KhBasisElement, R>] {
        typealias Component = Link.Component
        
        assert(components.count == 1) // currently supports only knots.
        
        let s0 = orientationPreservingState
        let L0 = spliced(by: s0)
        let comps = L0.components
        
        // splits comps into two groups.
        var queue:  [(Component, Int)] = [(comps[0], 0)]
        var result:  [Component : Int] = [:]
        
        while !queue.isEmpty {
            let (c, i) = queue.removeFirst()
            
            // crossings that touches c
            let xs = crossings.filter{ x in
                x.edges.contains{ e in c.edges.contains(e) }
            }
            
            // circles that are connected to c by xs
            let cs = xs.map{ x -> Component in
                let e = x.edges.first{ e in !c.edges.contains(e) }!
                return comps.first{ c1 in c1.edges.contains(e) }!
                }.unique()
            
            // queue circles with opposite color.
            for c1 in cs where !result.contains(key: c1) {
                queue.append((c1, 1 - i))
            }
            
            // append result.
            result[c] = i
        }
        
        assert(result.count == comps.count)
        
        typealias A = FreeModule<FreeTensor<KhBasisElement.E>, R>
        
        let (X, I) = (A.wrap(FreeTensor(.X)), A.wrap(FreeTensor(.I)))
        let (a, b) = (X - u * I, X - v * I)
        var (z0, z1) = (A.wrap(.identity), A.wrap(.identity))
        
        for c in comps {
            switch result[c]! {
            case 0:
                z0 = z0 ⊗ a
                z1 = z1 ⊗ b
            default:
                z0 = z0 ⊗ b
                z1 = z1 ⊗ a
            }
        }
        
        return [z0, z1].map { z in
            z.mapBasis{ t in KhBasisElement(s0, t) }
        }
    }
    
    public func LeeClassDivisibility<R: EuclideanRing>(_ type: R.Type, _ c: R) -> Int {
        let K = self
        let C = K.KhovanovChainComplex(R.self, h: c, t: .zero)
        let H0 = C.homology(0).freePart
        let a = K.LeeCycles(R.self, c)[0]
        
        var k = 0
        var v = H0.factorize(a)
        
        while (v[0] % c, v[1] % c) == (.zero, .zero) {
            v = [v[0] / c, v[1] / c]
            k += 1
        }
        
        return k
    }
    
    public func sHatInvariant<R: EuclideanRing>(_ type: R.Type, _ c: R) -> Int {
        let K = self
        let k = K.LeeClassDivisibility(R.self, c)
        let r = K.spliced(by: K.orientationPreservingState).components.count
        let w = K.writhe
        let s = 2 * k - r + w + 1
        return s
    }
}

public extension ModuleGridN where n == _2, A == KhBasisElement {
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
