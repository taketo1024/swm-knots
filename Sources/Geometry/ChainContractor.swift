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
    
    internal var generators = [A]()
    internal var relations = [C]()
    internal var fTable = [A : C]()
    
    public init(_ K: SimplicialComplex, _ type: R.Type) {
        self.list = K.maximalCells.flatMap{ $0.allSubsimplices().sorted() }.unique()
        self.run()
    }
    
    internal func f(_ c: C) -> C {
        return c.sum{ (s, a) in a * (fTable[s] ?? C.zero) }
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
        print("\tcorrespondance: ", fTable)
        print()
    }
    
    internal func iteration(_ i: Int, _ s: A) {
        let b = s.boundary(R.self)
        let f_b = f(b)
        
        print(i, "\ts: \(s)\n\tf(∂s) = \(f_b)")
        print()
        
        if isZero(f_b) {
            print("\tadd: ", s)
            
            generators.append(s)
            fTable[s] = C(s)
            
        } else {
            // extract relations from f_b
            if let (x, a) = f_b.filter({ (_, a) in a.isInvertible }).sorted(by: { $0.0 <= $1.0 }).last {
                print("\tremove: ", x, "=", a.inverse! * (f_b - a * C(x)))
                generators.remove(at: generators.index(of: x)!)
                
                for (y, f_y) in fTable.filter({ (_, f_y) in f_y[x] != R.zero }) {
                    let e = f_y[x] * a.inverse!
                    fTable[y] = f_y - e * f_b
                }
                
                for (i, r) in relations.enumerated().filter({ (_, r) in r[x] != R.zero}) {
                    let e = r[x] * a.inverse!
                    relations[i] = r - e * f_b
                }
            } else {
                print("new relation:", f_b)
                relations.append(f_b)
            }
        }
        
        fTable = fTable.filter{ $0.1 != C.zero }
        
        print()
        print("\tgenerators: ", generators)
        print("\trelations : ", relations)
        print()
        print("\tcorrespondance: ", fTable)
        print()
    }
}
