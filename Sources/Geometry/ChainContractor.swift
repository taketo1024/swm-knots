//
//  ChainContractor.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/02/15.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public class ChainContractor<R: EuclideanRing> {
    typealias A = Simplex
    typealias C = SimplicialChain<R>
    
    internal let list: [A]
    
    internal var gSymbols = [A]()
    internal var rSymbols  = [C]()
    
    internal var fTable = [A : C]()
    internal var hTable = [A : C]()
    
    public init(_ K: SimplicialComplex, _ type: R.Type) {
        self.list = K.maximalCells.flatMap{ $0.allSubsimplices().sorted() }.unique()
        self.run()
    }
    
    public var generators: [SimplicialChain<R>] {
        return gSymbols.map{ g($0) }
    }
    
    public var relations: [SimplicialChain<R>] {
        return rSymbols.map{ g($0) }
    }
    
    internal func f(_ s: A) -> C {
        return fTable[s] ?? C.zero
    }
    
    internal func f(_ c: C) -> C {
        return c.sum{ (s, a) in a * f(s) }
    }
    
    internal func g(_ s: A) -> C {
        return C(s) + h(s.boundary(R.self))
    }
    
    internal func g(_ c: C) -> C {
        return c.sum{ (s, a) in a * g(s) }
    }
    
    internal func h(_ s: A) -> C {
        return hTable[s] ?? C.zero
    }
    
    internal func h(_ c: C) -> C {
        return c.sum{ (s, a) in a * h(s) }
    }
    
    internal func isZero(_ c: C) -> Bool {
        if rSymbols.isEmpty {
            return c == C.zero
        }
        
        let A = DynamicMatrix<R>(rows: rSymbols.count + 1, cols: gSymbols.count) { (i, j) in
            let x = gSymbols[j]
            if i < rSymbols.count {
                return rSymbols[i][x]
            } else {
                return c[x]
            }
        }
        
        let E = A.eliminate(form: .RowEchelon)
        return E.rank == rSymbols.count
    }
    
    internal func run() {
        for (i, s) in list.enumerated() {
            iteration(i, s)
        }
        
        print()
        print("final result")
        print("------------")
        print("\tgenerators: ", generators)
        print("\trelations : ", relations)
        print()
    }
    
    internal func iteration(_ i: Int, _ s: A) {
        let boundary = s.boundary(R.self)
        let f_boundary = f(boundary)
        
        print(i, "\ts: \(s)\n\tf(∂s) = \(f_boundary)")
        print()
        
        if isZero(f_boundary) {
            print("\tadd: ", s)
            
            gSymbols.append(s)
            fTable[s] = C(s)
            
        } else {
            // TODO: extract relations from f_b
            if let (x, a) = f_boundary.filter({ (_, a) in a.isInvertible }).sorted(by: { $0.0 <= $1.0 }).last {
                print("\tremove: ", x, "=", a.inverse! * (f_boundary - a * C(x)))
                gSymbols.remove(at: gSymbols.index(of: x)!)
                
                for (y, f_y) in fTable.filter({ (_, f_y) in f_y[x] != R.zero }) {
                    let e = f_y[x] * a.inverse!
                    fTable[y] = f_y - e * f_boundary
                }
                fTable = fTable.filter{ $0.1 != C.zero }

                for (i, r) in rSymbols.enumerated().filter({ (_, r) in r[x] != R.zero}) {
                    let e = r[x] * a.inverse!
                    rSymbols[i] = r - e * f_boundary
                }
                rSymbols = rSymbols.filter{ $0 != C.zero }
                
            } else {
                print("new relation:", f_boundary)
                rSymbols.append(f_boundary)
            }
            
            let t = s.face(0)
            let v = h(t) - C(s) - h(boundary)
            hTable[t] = v
        }
        
        print()
        print("\tgenerators: ", gSymbols)
        print("\trelations : ", rSymbols)
        print()
    }
}
