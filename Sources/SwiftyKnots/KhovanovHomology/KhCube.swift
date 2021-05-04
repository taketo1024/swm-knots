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
    public let link: Link
    let product: KhAlgebraGenerator.Product<R>
    let coproduct: KhAlgebraGenerator.Coproduct<R>
    
    public typealias EdgeMap = ModuleEnd<LinearCombination<KhComplexGenerator, R>>
    
    private let verticesCache: CacheDictionary<Link.State, Vertex>   = CacheDictionary([:])
    private let edgeMapsCache: CacheDictionary<StatePair, EdgeMap>   = CacheDictionary([:])
    private let targetStatesCache: CacheDictionary<Link.State, [Link.State]> = .empty

    init(link L: Link, product: KhAlgebraGenerator.Product<R>, coproduct: KhAlgebraGenerator.Coproduct<R>) {
        self.link = L
        self.product = product
        self.coproduct = coproduct
    }
    
    public init(link L: Link, h: R = R.zero, t: R = R.zero) {
        self.init(
            link: L,
            product: KhAlgebraGenerator.product(h: h, t: t),
            coproduct: KhAlgebraGenerator.coproduct(h: h, t: t)
        )
    }
    
    public subscript(s: Link.State) -> Vertex {
        verticesCache.useCacheOrSet(key: s) { Vertex(link, s) }
    }
    
    public var dim: Int {
        link.crossingNumber
    }
    
    public var startVertex: Vertex {
        self[Link.State(repeating: .resolution0, count: dim)]
    }
    
    public var endVertex: Vertex {
        self[Link.State(repeating: .resolution1, count: dim)]
    }
    
    public func states(ofDegree i: Int) -> Set<Link.State> {
        // {0, 2, 5}  ->  (101001)
        Set((0 ..< dim).choose(i).map { (I: [Int]) -> Link.State in
            Link.State( (0 ..< dim).map{ i in I.contains(i) ? .resolution1 : .resolution0 } )
        })
    }
    
    //  101001  ->  { (-, 111001), (+, 101101), (+, 101011) }
    public func targetStates(from state: Link.State) -> [Link.State] {
        return targetStatesCache.useCacheOrSet(key: state) {
            (0 ..< state.count)
            .filter{ i in state[i] == .resolution0 }
            .map { i in Link.State( state.replaced(at: i, with: .resolution1) ) }
        }
    }
    
    public func edgeSign(from s0: Link.State, to s1: Link.State) -> R {
        guard let i = (0 ..< s0.count).first(where: { j in s0[j] != s1[j] }) else {
            fatalError("invalid states: \(s0), \(s1)")
        }
        let e = (0 ... i).count{ j in s0[j] == 1 }
        return R(from: (-1).pow(e))
    }
    
    public enum EdgeDescription {
        case merge(from: (Int, Int), to: Int)
        case split(from: Int, to: (Int, Int))
    }
    
    public func edgeDescription(from s0: Link.State, to s1: Link.State) -> EdgeDescription {
        let (L0, L1) = (self[s0].circles, self[s1].circles)
        let (c1, c2) = (L0.components, L1.components)
        let (d1, d2) = (c1.filter{ !c2.contains($0) }, c2.filter{ !c1.contains($0) })
        
        switch (d1.count, d2.count) {
        case (2, 1):
            let (i1, i2) = (c1.firstIndex(of: d1[0])!, c1.firstIndex(of: d1[1])!)
            let j = c2.firstIndex(of: d2[0])!
            return .merge(from: (i1, i2), to: j)
            
        case (1, 2):
            let i = c1.firstIndex(of: d1[0])!
            let (j1, j2) = (c2.firstIndex(of: d2[0])!, c2.firstIndex(of: d2[1])!)
            return .split(from: i, to: (j1, j2))
            
        default:
            fatalError()
        }
    }
    
    public func edgeMap(from s0: Link.State, to s1: Link.State) -> EdgeMap {
        let pair = StatePair(from: s0, to: s1)
        return edgeMapsCache.useCacheOrSet(key: pair) {
            let ε = edgeSign(from: s0, to: s1)
            switch self.edgeDescription(from: s0, to: s1) {
            case let .merge(from: (i1, i2), to: j):
                let m = self.product
                return ModuleHom.linearlyExtend{ x in
                    ε * x.applied(m, inputIndices: (i1, i2), outputIndex: j, nextState: s1)
                }
            case let .split(from: i, to: (j1, j2)):
                let Δ = self.coproduct
                return ModuleHom.linearlyExtend{ x in
                    ε * x.applied(Δ, inputIndex: i, outputIndices: (j1, j2), nextState: s1)
                }
            }
        }
    }
    
    public func differential(_ i: Int) -> ModuleEnd<LinearCombination<KhComplexGenerator, R>> {
        ModuleHom.linearlyExtend { (x: KhComplexGenerator) in
            self.targetStates(from: x.state).sum { target in
                self.edgeMap(from: x.state, to: target)(x)
            }
        }
    }
    
    public func asChainComplex() -> ChainComplex1<LinearCombination<KhComplexGenerator, R>> {
        ChainComplex1(
            type: .ascending,
            support: 0 ... dim,
            sequence: { i in
                let n = self.dim
                guard (0 ... n).contains(i) else {
                    return .zeroModule
                }
                
                let states = self.states(ofDegree: i)
                let generators = states.flatMap{ self[$0].generators }
                
                return ModuleObject(basis: generators)
            },
            differential: { i in self.differential(i) }
        )
    }
    
    public func describe(_ s: Link.State) {
        print("\(s): \(self[s])")
    }
    
    public struct Vertex: CustomStringConvertible {
        public let state: Link.State
        public let circles: Link
        public let generators: [KhComplexGenerator]
        
        init(_ L: Link, _ state: Link.State) {
            self.state = state
            self.circles = L.resolved(by: state)
            
            let r = circles.components.count
            self.generators = KhComplexGenerator.generateBasis(state: state, power: r)
        }
        
        var maxQdegree: Int {
             generators.map{ $0.quantumDegree }.max() ?? 0
        }
        
        var minQdegree: Int {
             generators.map{ $0.quantumDegree }.min() ?? 0
        }
        
        public var description: String {
            generators.description
        }
    }
    
    private struct StatePair: Hashable {
        let from: Link.State
        let to:   Link.State
    }
}
