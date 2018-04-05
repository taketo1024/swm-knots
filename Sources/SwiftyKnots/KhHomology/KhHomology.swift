//
//  KhHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public typealias KhHomology<R: EuclideanRing> = Cohomology<KhTensorElement, R>
public extension KhHomology where T == Ascending, A == KhTensorElement, R: EuclideanRing {
    public convenience init(_ L: Link, _ type: R.Type) {
        let name = "Kh(\(L.name); \(R.symbol))"
        let C = KhChainComplex(L, R.self)
        self.init(name: name, chainComplex: C)
    }
    
    public subscript(i: Int, j: Int) -> Summand {
        let ss = self[i].summands.filter{ s in s.degree == j }
        let f = { (x: FreeModule<A, R>) -> [R] in [] } // TODO
        let str = SimpleModuleStructure(ss, f)
        return Summand(self, str)
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
