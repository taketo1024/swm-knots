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
    internal var done = Set<S>()
    
    internal var generators = [S]()
    internal var relations  = [C]()
    internal var diff = [S : C]()

    internal var fNodes = [S : Node]()
    internal var hNodes = [S : Node]()
    
    public init(_ K: SimplicialComplex, _ type: R.Type) {
        self.K = K
    }
    
    internal func f(_ s: S) -> C {
        return fNodes[s]!.collect()
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
        return hNodes[s]!.collect(searchPathFirst: true)
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
        if done.contains(s) {
            return []
        }
        
        func extract(_ s: S) -> [S] {
            return [s] + s.faces().filter({ !done.contains($0) }).flatMap{ extract($0) }
        }
        return extract(s).reversed().unique()
    }
    
    public func run(doAssert: Bool = false) {
        for s in K.maximalCells.sorted() {
            let list = makeList(s)
            
            for s in list {
                iteration(s)
            }
        }
        
        if doAssert {
            assertChainContraction()
        }
        
        log("")
        log("final result")
        log("------------")
        log("generators:")
        log(generators.map{ "\($0.dim): \(g($0))"}.joined(separator: ",\n"))
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
        
        done.insert(s)
        
        log("\tgenerators: \(generators)")
        log("")
//        log("\tf: \(fNodes)")
//        log("\th: \(hNodes)")
//        log("")
        
//        assertChainContraction()
    }
    
    internal func assertChainContraction() {
        for s in done {
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
        let chain = K.validDims.map{ (i) -> (CC.ChainBasis, CC.BoundaryMap, CC.BoundaryMatrix) in
            
            let from = generators.filter{ $0.dim == i }
            let to   = generators.filter{ $0.dim == i - 1 }
            let map  = CC.BoundaryMap.zero // TODO
            
            let toIndex = Dictionary(pairs: to.enumerated().map{($1, $0)}) // [toCell: toIndex]
            
            let components = from.enumerated().flatMap{ (j, s) -> [MatrixComponent<R>] in
                return diff[s].flatMap { b -> [MatrixComponent<R>] in
                    b.map { (t, r) in
                        (toIndex[t]!, j, r)
                    }
                    } ?? []
            }
            let matrix = ComputationalMatrix(rows: to.count, cols: from.count, components: components)
            
            return (from, map, matrix)
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
        
        func collect(searchPathFirst: Bool = false) -> C {
            if !searchPathFirst {
                return value + refs.sum { (n, r) in r * n.collect() }
                
            } else {
                if isZero { return C.zero }
                
                print("h(\(cell)) = \(self)")
                
                var sum = C.zero
                var queue = [self : R.identity]
                var stash = [Node : R]()
                
                while !queue.isEmpty {
                    print("\tsum  :", sum)
                    print("\tqueue:", queue.map{ ($0.1, $0.0.cell)} )
                    print("\tstash:", stash.map{ ($0.1, $0.0.cell)} )

                    let (n1, a1) = queue.anyElement!
                    queue.removeValue(forKey: n1)
                    
                    print()
                    print("\tpop  :", (a1, n1))
                    
                    sum = sum + a1 * n1.value
                    for (n2, a2) in n1.refs {
                        let a = a1 * a2
                        if n1 == n2 {
                            stash[n1] = stash[n1, default: R.zero] + a
                        } else if stash[n2] != nil {
                            stash[n2] = stash[n2]! + a
                        } else if !n2.isZero {
                            queue[n2] = queue[n2, default: R.zero] + a
                        }
                    }
                    
                    print()
                }
                
                assert(stash.forAll{ $0.value == R.zero })
                
                print("\th(\(cell)) = \(sum)")
                print()
                
                return sum
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
        Debug.log(msg, true)
    }
}
