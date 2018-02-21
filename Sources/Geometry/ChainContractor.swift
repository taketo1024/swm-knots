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

    internal var fTable = [S : C]()
    internal var hTable = [S : C]()
    
    public init(_ K: SimplicialComplex, _ type: R.Type) {
        self.K = K
        self.run()
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
    
    internal func f(_ s: S) -> C {
        return fTable[s]!.sum { (t, a) in
            (s == t) ? a * C(t) : a * f(t)
        }
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
    
    internal func h(_ s: S, path: Bool = false) -> C {
        return hTable[s]!.sum { (t, a) in
            if t.dim == s.dim + 1 || (path && t == s) {
                return a * C(t)
            } else if s != t {
                return a * h(t, path: path)
            } else {
                return C.zero
            }
        }
    }
    
    internal func h(_ c: C, path: Bool = false) -> C {
        return c.sum{ (s, a) in a * h(s, path: path) }
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
    
    internal func run() {
        for s in K.maximalCells {
            let list = makeList(s)
            
            for s in list {
                iteration(s)
            }
        }
        
//        assertChainContraction()
        
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
        
        hTable[s] = C(s)
        
        let bs = C(s).boundary()
        let f_bs = f(bs)
        
        log("\(step)\t\(s): f∂ = \(f_bs)")
        log("")
        
        if isZero(f_bs) {
            log("\tadd: \(s)")
            
            fTable[s] = C(s)
            generators.append(s)
            
        } else {
            let candidates = f_bs
                .filter{ (t1, a) in a.isInvertible && diff[t1] == nil }
                .sorted{ (v1, v2) in v1.0 <= v2.0 } // TODO
            
            if let (t1, a) = candidates.first {
                let e = a.inverse!
                log("\tremove: \(t1) = \(-e * (f_bs - a * C(t1)))")
                
                fTable[s] = C.zero
                generators.remove(at: generators.index(of: t1)!)
                
                fTable[t1] = fTable[t1]! - e * f_bs
                hTable[t1] = hTable[t1]! - e * (C(s) + h(bs, path: true)) // TODO improve performance!
                
                for (i, r) in relations.enumerated().filter({ (_, r) in r[t1] != R.zero}) {
                    let e = r[t1] * a.inverse!
                    relations[i] = r - e * f_bs
                }
                
                for (s, b) in diff.filter({ (_, b) in b[t1] != R.zero }) {
                    let e = b[t1] * a.inverse!
                    diff[s] = b - e * f_bs
                }
                
            } else {
                log("\tadd: \(s) with diff: \(f_bs)")
                
                fTable[s] = C(s)
                generators.append(s)
                relations.append(f_bs)
                diff[s] = f_bs
            }
        }
        
        done.insert(s)
        
        log("\tgenerators: \(generators)")
        log("")
        log("\tf: \(fTable)")
        log("\th: \(hTable)")
        log("")
        
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
    }
}
