//
//  KhHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public typealias KhHomology<R: EuclideanRing> = Cohomology<KhBasisElement, R>
public extension KhHomology where T == Ascending, A == KhBasisElement, R: EuclideanRing {
    public convenience init(_ L: Link, _ type: R.Type) {
        let name = "Kh(\(L.name); \(R.symbol))"
        let C = KhChainComplex(L, R.self)
        self.init(name: name, chainComplex: C)
    }
    
    public subscript(i: Int, j: Int) -> Summand {
        let filtered = self[i].summands.enumerated().compactMap{ (k, s) in
            (s.degree == j) ? (k, s) : nil
        }
        
        let indices  = filtered.map{ $0.0 }
        let summands = filtered.map{ $0.1 }
        
        let f = { (x: FreeModule<A, R>) -> [R] in
            let y = self[i].factorize(x)
            return indices.map{ k in y[k] }
        }
        
        let str = SimpleModuleStructure(summands, f)
        return Summand(self, str)
    }
    
    public var validDegrees: [(Int, Int)] {
        return (offset ... topDegree).flatMap { i in
            self[i].summands.map { s in (i, s.generator.degree) }
        }
    }
    
    public func KhLee(_ i: Int, _ j: Int) {
        let (prev, this, next) = (self[i - 1, j - 4], self[i, j], self[i + 1, j + 4])
        
        print(prev, "\t->\t[", this, "]\t->\t", next, "\n")
        
        func matrix(from: Summand, to: Summand) -> ComputationalMatrix<R> {
            let grid = from.generators.flatMap { g -> [R] in
                let x = g.representative
                let y = x.sum { (e, r) in
                    r * e.transit(μL, ΔL)
                }
                return to.factorize(y)
            }
            return ComputationalMatrix(rows: to.generators.count, cols: from.generators.count, grid: grid).transpose()
        }
        
        let A = matrix(from: prev, to: this)
        let B = matrix(from: this, to: next)
        
        print("In: \n", A.asDynamicMatrix().detailDescription, "\n")
        print("Out:\n", B.asDynamicMatrix().detailDescription, "\n")
    }
    
    public func printSummands() {
        let cols = (offset ... topDegree).toArray()
        let degs = cols.flatMap{ i in self[i].summands.map{ $0.degree} }.unique()
        
        guard let j0 = degs.min(), let j1 = degs.max() else {
            return
        }
        
        let rows = (j0 ... j1).filter{ ($0 - j0).isEven }.reversed().toArray()
        printTable("j\\i", rows: rows, cols: cols) { (j, i) in self[i, j] }
    }
}

private func μL(_ e1: KhBasisElement.E, _ e2: KhBasisElement.E) -> [KhBasisElement.E] {
    switch (e1, e2) {
    case (.I, .I), (.I, .X), (.X, .I): return []
    case (.X, .X): return [.I]
    }
}

private func ΔL(_ e: KhBasisElement.E) -> [(KhBasisElement.E, KhBasisElement.E)] {
    switch e {
    case .I: return []
    case .X: return [(.I, .I)]
    }
}
