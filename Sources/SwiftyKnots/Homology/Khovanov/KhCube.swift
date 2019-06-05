//
//  ModuleCube.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/06/06.
//

import Foundation
import SwiftyMath
import SwiftyHomology

// An n-dim cube with Modules on all vertices I ∈ {0, 1}^n .

extension ModuleObject {
    public static func generate<A: FreeModuleGenerator>(from generators: [A], over: R.Type) -> ModuleObject<FreeModule<A, R>> {
        
        let indexer = generators.indexer()
        let wrapped = generators.map{ FreeModule<A, R>.wrap($0) }
        return ModuleObject<FreeModule<A, R>>(basis: wrapped) { z in
            let comps = z.elements.map{ (a, r) in (indexer(a)!, 0, r) }
            return DVector(size: generators.count, components: comps)
        }
    }
}

public struct KhCube<R: Ring> {
    public struct Vertex: CustomStringConvertible {
        public let state: Link.State
        public let splicedLink: Link
        public let generators: [KhEnhancedState]
        
        init(_ L: Link, _ state: Link.State) {
            self.state = state
            self.splicedLink = L.spliced(by: state)
            
            let r = splicedLink.components.count
            self.generators = KhEnhancedState.generateBasis(state: state, power: r)
        }
        
        public var description: String {
            return generators.description
        }
    }
    
    public typealias EdgeMap = ModuleEnd<FreeModule<KhEnhancedState, R>>
    
    public let link: Link
    let product: KhEnhancedState.Product<R>
    let coproduct: KhEnhancedState.Coproduct<R>
    
    private let verticesCache: Cache<[Link.State : Vertex]> = Cache([:])
    
    init(_ L: Link, _ m: KhEnhancedState.Product<R>, _ Δ: KhEnhancedState.Coproduct<R>) {
        self.link = L
        self.product = m
        self.coproduct = Δ
    }
    
    public init(link L: Link, h: R = R.zero, t: R = R.zero) {
        self.init(L, KhEnhancedState.Product(h, t), KhEnhancedState.Coproduct(h, t))
    }
    
    public subscript(s: Link.State) -> Vertex {
        let v: Vertex
        if let cached = verticesCache.value![s] {
            v = cached
        } else {
            v = Vertex(link, s)
            verticesCache.value![s] = v
        }
        return v
    }
    
    public var dim: Int {
        return link.crossingNumber
    }
    
    public var startVertex: Vertex {
        return self[Link.State([0].repeated(dim))]
    }
    
    public var endVertex: Vertex {
        return self[Link.State([1].repeated(dim))]
    }
    
    func targetStates(from s: Link.State) -> [(sign: R, state: Link.State)] {
        return s.components.enumerated()
            .filter{ $0.element == 0 }
            .map { (i, _) in
                let c = s.components.enumerated().count{ (j, a) in j < i && a == 1 }
                let sign = R(from: (-1).pow(c))
                let target = Link.State( s.components.replaced(at: i, with: 1) )
                return (sign, target)
        }
    }
    
    public func edgeMap(from s0: Link.State, to s1: Link.State) -> EdgeMap {
        let (L0, L1) = (self[s0].splicedLink, self[s1].splicedLink)
        let (c1, c2) = (L0.components, L1.components)
        let (d1, d2) = (c1.filter{ !c2.contains($0) }, c2.filter{ !c1.contains($0) })
        switch (d1.count, d2.count) {
        case (2, 1):
            let (i1, i2) = (c1.firstIndex(of: d1[0])!, c1.firstIndex(of: d1[1])!)
            let j = c2.firstIndex(of: d2[0])!
            return ModuleHom.linearlyExtend{ x in
                self.product.applied(to: x, at: (i1, i2), to: j, state: s1)
            }
            
        case (1, 2):
            let i = c1.firstIndex(of: d1[0])!
            let (j1, j2) = (c2.firstIndex(of: d2[0])!, c2.firstIndex(of: d2[1])!)
            return ModuleHom.linearlyExtend{ x in
                self.coproduct.applied(to: x, at: i, to: (j1, j2), state: s1)
            }
            
        default:
            return .zero
        }
    }
    
    public func fold1() -> ChainComplex1<FreeModule<KhEnhancedState, R>> {
        return ChainComplex1(ascendingSequence: { i in
            let n = self.dim
            guard (0 ... n).contains(i) else {
                return .zeroModule
            }
            
            let states = n.choose(i).map { c in
                Link.State( (0 ..< n).map{ c.contains($0) ? 1 : 0 } )
            }
            let generators = states.flatMap{ self[$0].generators }
            return ModuleObject<FreeModule<KhEnhancedState, R>>.generate(from: generators, over: R.self)
        }, differential: { i in
            ModuleHom.linearlyExtend { (x: KhEnhancedState) in
                self.targetStates(from: x.state).sum { (e, target) in
                    e * self.edgeMap(from: x.state, to: target).applied(to: .wrap(x))
                }
            }
        })
    }
    
    public func fold2() -> ChainComplex2<FreeModule<KhEnhancedState, R>> {
        return ChainComplex2(grid: ModuleGrid { I in
            let (i, j) = (I[0], I[1])
            let n = self.dim
            guard (0 ... n).contains(i) else {
                return .zeroModule
            }
            
            let states = n.choose(i).map { c in
                Link.State( (0 ..< n).map{ c.contains($0) ? 1 : 0 } )
            }
            let generators = states.flatMap{ self[$0].generators.filter{ $0.degree == j } }
            return ModuleObject<FreeModule<KhEnhancedState, R>>.generate(from: generators, over: R.self)
        }, differential: ChainMap2(multiDegree: IntList(1, 0)) { I in
            ModuleHom.linearlyExtend { (x: KhEnhancedState) in
                self.targetStates(from: x.state).sum { (e, target) in
                    e * self.edgeMap(from: x.state, to: target).applied(to: .wrap(x))
                }
            }
        })
    }
    
    public func describe(_ s: Link.State) {
        print("\(s): \(self[s])")
    }
}
