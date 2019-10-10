//
//  ModuleCube.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/06/06.
//

import SwiftyMath
import SwiftyHomology

// An n-dim cube with Modules on all vertices I ∈ {0, 1}^n .

public struct KhCube<R: Ring> {
    public struct Vertex: CustomStringConvertible {
        public let state: Link.State
        public let splicedLink: Link
        public let generators: [KhEnhancedState]
        
        fileprivate let targetStates: [(sign: R, state: Link.State)]
        
        init(_ L: Link, _ state: Link.State) {
            self.state = state
            self.splicedLink = L.spliced(by: state)
            
            let r = splicedLink.components.count
            self.generators = KhEnhancedState.generateBasis(state: state, power: r)
            
            //  101001  ->  { (-, 111001), (+, 101101), (+, 101011) }
            self.targetStates = (0 ..< L.crossingNumber)
                .filter{ i in state[i] == 0 }
                .map { i in
                    let e = state[0 ..< i].count{ $0 == 1 }
                    let sign = R(from: (-1).pow(e))
                    let target = Link.State( state.replaced(at: i, with: 1) )
                    return (sign, target)
                }
        }
        
        public var description: String {
            generators.description
        }
    }
    
    private struct StatePair: Hashable {
        let from: Link.State
        let to:   Link.State
    }
    
    public typealias EdgeMap = ModuleEnd<FreeModule<KhEnhancedState, R>>
    
    public let link: Link
    let product: KhEnhancedState.Product<R>
    let coproduct: KhEnhancedState.Coproduct<R>
    
    private let statesCache:   CacheDictionary<Int, Set<Link.State>> = CacheDictionary([:])
    private let verticesCache: CacheDictionary<Link.State, Vertex>   = CacheDictionary([:])
    private let edgeMapsCache: CacheDictionary<StatePair, EdgeMap>   = CacheDictionary([:])

    init(_ L: Link, _ m: KhEnhancedState.Product<R>, _ Δ: KhEnhancedState.Coproduct<R>) {
        self.link = L
        self.product = m
        self.coproduct = Δ
    }
    
    public init(link L: Link, h: R = R.zero, t: R = R.zero) {
        self.init(L, KhEnhancedState.Product(h, t), KhEnhancedState.Coproduct(h, t))
    }
    
    public subscript(s: Link.State) -> Vertex {
        verticesCache.useCacheOrSet(key: s) { Vertex(link, s) }
    }
    
    public var dim: Int {
        link.crossingNumber
    }
    
    public var startVertex: Vertex {
        self[Link.State([0] * dim)]
    }
    
    public var endVertex: Vertex {
        self[Link.State([1] * dim)]
    }
    
    public func states(ofDegree i: Int) -> Set<Link.State> {
        // {0, 2, 5}  ->  (101001)
        statesCache.useCacheOrSet(key: i) {
            Set((0 ..< dim).choose(i).map { (I: [Int]) -> Link.State in
                Link.State( (0 ..< dim).map{ i in I.contains(i) ? 1 : 0 } )
            })
        }
    }
    
    public func edgeMap(from s0: Link.State, to s1: Link.State) -> EdgeMap {
        let pair = StatePair(from: s0, to: s1)
        return edgeMapsCache.useCacheOrSet(key: pair) {
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
    }
    
    public func differential(_ i: Int) -> ModuleEnd<FreeModule<KhEnhancedState, R>> {
        ModuleHom.linearlyExtend { (x: KhEnhancedState) in
            let v = self[x.state]
            return v.targetStates.sum { (ε, target) -> FreeModule<KhEnhancedState, R> in
                ε * self.edgeMap(from: x.state, to: target).applied(to: .wrap(x))
            }
        }
    }
    
    public func fold() -> ChainComplex1<FreeModule<KhEnhancedState, R>> {
        ChainComplex1(
            type: .ascending,
            supported: 0 ... dim,
            sequence: { i in
                let n = self.dim
                guard (0 ... n).contains(i) else {
                    return .zeroModule
                }
                
                let states = self.states(ofDegree: i)
                let generators = states.flatMap{ self[$0].generators }
                
                return ModuleObject(basis: generators)
            },
            differential: { i in self.differential(i) })
    }
    
    public func describe(_ s: Link.State) {
        print("\(s): \(self[s])")
    }
}
