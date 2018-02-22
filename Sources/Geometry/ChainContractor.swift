//
//  ChainContractor.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/02/15.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public class ChainContractor<R: EuclideanRing> {
    typealias S = Simplex
    typealias C = SimplicialChain<R>
    
    internal let K: SimplicialComplex
    
    internal var step = -1
    internal var doneCells = Set<S>()
    internal var allDone = false
    internal var debug = false
    
    internal var generators = [S]()
    internal var relations  = [C]()
    internal var diff = [S : C]()

    internal var fNodes = [S : Node]()
    internal var hNodes = [S : Node]()
    
    public init(_ K: SimplicialComplex, _ type: R.Type, debug: Bool = false) {
        self.K = K
        self.debug = debug
        self.run()
    }
    
    internal func f(_ s: S) -> C {
        return fNodes[s]!.collect(flatten: allDone)
    }
    
    internal func f(_ c: C) -> C {
        return c.sum{ (s, a) in a * f(s) }
    }
    
    internal func g(_ s: S) -> C {
        return C(s) + h(C(s).boundary())
    }
    
    internal func g(_ c: C) -> C {
        return c.sum{ (s, a) in a * g(s) }
    }
    
    internal func h(_ s: S) -> C {
        return hNodes[s]!.collect(flatten: allDone)
    }
    
    internal func h(_ c: C, path: Bool = false) -> C {
        return c.sum{ (s, a) in a * h(s) }
    }
    
    internal func isZero(_ c: C) -> Bool {
        if relations.isEmpty {
            return c == C.zero
        }
        
        let A = DynamicMatrix<R>(rows: relations.count + 1, cols: generators.count) { (i, j) in
            let x = generators[j]
            if i < relations.count {
                return relations[i][x]
            } else {
                return c[x]
            }
        }
        
        let E = A.eliminate(form: .RowEchelon)
        return E.rank == relations.count
    }
    
    internal func makeList(_ s: S) -> [S] {
        if doneCells.contains(s) {
            return []
        }
        
        func extract(_ s: S) -> [S] {
            return [s] + s.faces().filter({ !doneCells.contains($0) }).flatMap{ extract($0) }
        }
        return extract(s).reversed().unique()
    }
    
    internal func run() {
        for s in K.maximalCells.sorted() {
            let list = makeList(s)
            
            for s in list {
                iteration(s)
            }
        }
        
        allDone = true
        
        log("")
        log("generators:")
        log(generators.map{ "\t\($0.dim): \($0)"}.joined(separator: ",\n"))
        
        if !relations.isEmpty {
            log("")
            log("relations:")
            log(relations.map { "\t\($0.anyElement!.0.dim): \($0)"}.joined(separator: ",\n"))
        }
        log("")
    }
    
    @_specialize(where R == ComputationSpecializedRing)
    internal func iteration(_ s: S) {
        step += 1
        
        let bs = C(s).boundary()
        let f_bs = f(bs)
        
        log("\(step)\t\(s): f∂ = \(f_bs)")
        log("")
        
        if isZero(f_bs) {
            log("\tadd: \(s)")
            
            generators.append(s)
            
            fNodes[s] = Node(s, C(s))
            hNodes[s] = Node(s, C.zero)
            
        } else {
            let candidates = f_bs
                .filter{ (t1, a) in a.isInvertible && diff[t1] == nil }
                .sorted{ (v1, v2) in v1.0 <= v2.0 } // TODO
            
            if let (t1, a) = candidates.last {
                let e = a.inverse!
                log("\tremove: \(t1) = \(-e * (f_bs - a * C(t1)))")
                
                generators.remove(at: generators.index(of: t1)!)
                
                for (i, r) in relations.enumerated().filter({ (_, r) in r[t1] != R.zero}) {
                    let e = r[t1] * a.inverse!
                    relations[i] = r - e * f_bs
                }
                
                for (s, b) in diff.filter({ (_, b) in b[t1] != R.zero }) {
                    let e = b[t1] * a.inverse!
                    diff[s] = b - e * f_bs
                }
                
                fNodes[s] = Node(s, C.zero)
                hNodes[s] = Node(s, C.zero)
                
                fNodes[t1]!.value = C.zero
                fNodes[t1]!.refs = (C(t1) - e * f_bs).map{ (t, a) in (fNodes[t]!, a) }
                
                hNodes[t1]!.value = -e * C(s)
                hNodes[t1]!.refs = (C(t1) - e * bs).map{ (t, a) in (hNodes[t]!, a) }
                
            } else {
                log("\tadd: \(s) with diff: \(f_bs)")
                
                generators.append(s)
                relations.append(f_bs)
                diff[s] = f_bs
                
                fNodes[s] = Node(s, C(s))
                hNodes[s] = Node(s, C.zero)
            }
        }
        
        doneCells.insert(s)
        
        log("\tgenerators: \(generators)")
        if !relations.isEmpty {
            log("relations: \(relations)")
        }
        log("")
    }
    
    public func assertChainContraction() {
        for s in doneCells {
            let a1 = g(f(s)) - C(s)
            let a2 = h(C(s).boundary()) + h(s).boundary()
            assert(a1 == a2, "(gf - 1)(\(s)) = \(a1),\n(h∂ + ∂h)(\(s)) = \(a2)\n")
        }
        
        for s in generators {
            let b1 = f(g(s))
            assert(b1 == C(s), "fg(\(s)) = \(b1)\n")
        }
        
        for s in generators.filter({ diff[$0] == nil}) {
            let b = g(s).boundary()
            assert(b == C.zero, "∂s = \(b), should be 0.\n")
        }
        
        log("assertion complete.")
    }
    
    public var contractedChainComplex: ChainComplex<Simplex, R> {
        typealias CC = ChainComplex<S, R>
        let chain = K.validDims.map{ (i) -> (CC.ChainBasis, CC.BoundaryMap) in
            
            let from = generators.filter { s in s.dim == i }
            let map  = CC.BoundaryMap { s in self.diff[s] ?? C.zero }
            return (from, map)
        }
        
        return CC(name: K.name, chain)
    }
    
    public var contractedCochainComplex: CochainComplex<Dual<Simplex>, R> {
        typealias CC = CochainComplex<Dual<S>, R>
        let chain = K.validDims.map{ (i) -> (CC.ChainBasis, CC.BoundaryMap) in
            let from = generators.filter { s in s.dim == i }
            let map  = CC.BoundaryMap { d in
                let s = d.base
                let e = R(intValue: (-1).pow(d.degree + 1))
                let to = self.generators.filter { s in s.dim == i + 1 }
                let vals = to.flatMap { t -> (Dual<S>, R)? in
                    let a = self.diff[t]?[s] ?? R.zero
                    return (a != R.zero) ? (Dual(t), e * a) : nil
                }
                return SimplicialCochain(vals)
            }
            return (from.map{ Dual($0) }, map)
        }
        
        return CC(name: K.name, chain)
    }
    
    internal class Node: Hashable, CustomStringConvertible {
        let cell: S
        var value: C
        var refs: [(Node, R)] = []
        
        init(_ cell: S, _ value: C) {
            self.cell = cell
            self.value = value
        }
        
        var isZero: Bool {
            return value == C.zero && refs.isEmpty
        }
        
        func collect(flatten: Bool = false) -> C {
            var basket = [Node : R]()
            let value = _collect(1, &basket)
            
            assert(basket.forAll{ $0.value == R.zero })
            
            if flatten {
                self.value = value
                self.refs = []
            }
            
            return value
        }
        
        @_specialize(where R == ComputationSpecializedRing)
        private func _collect(_ a: R, _ basket: inout [Node : R]) -> C {
            return value + refs.filter{ (n, r) in
                if n == self {
                    basket[n] = basket[n, default: R.zero] + r
                    return false
                } else if basket[n] != nil {
                    basket[n] = basket[n]! + a * r
                    return false
                } else {
                    return !isZero
                }
            }.sum {
                (n, r) in r * n._collect(a * r, &basket)
            }
        }
        
        var hashValue: Int {
            return cell.hashValue
        }
        
        static func ==(lhs: Node, rhs: Node) -> Bool {
            return lhs.cell == rhs.cell
        }
        
        public var description: String {
            return refs.isEmpty
                ? "\(cell) : {\(value)}"
                : "\(cell) : {\(value) -> [\(refs.map{ (n, r) in "\(r)\(n.cell)"}.joined(separator: ", "))]}"
        }
    }
    
    internal func log(_ msg: @autoclosure () -> String) {
        Debug.log(msg, debug)
    }
}
