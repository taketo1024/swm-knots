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
    
    public var bigradedSummands: [(i: Int, j: Int, SimpleModuleStructure<KhTensorElement, R>.Summand)] {
        return (offset ... topDegree).flatMap { i in
            self[i].summands.map { s in (i, s.generator.degree, s) }
        }
    }
    
    public func printSummands() {
        let summands = bigradedSummands
        if summands.isEmpty {
            return
        }
        
        let table = summands.group{ $0.i }.mapValues { list in
            list.group{ $0.j }.mapValues{ $0.map{ $0.2 } }
        }
        
        let I = summands.map{ $0.i }.unique()
        let cols = (I.min()! ... I.max()!).toArray()
        
        let J = summands.map{ $0.j }.unique()
        let rows = (J.min()! ... J.max()!).reversed().toArray()
        
        printTable("j\\i", rows: rows, cols: cols) { (j, i) in
            table[i]?[j].flatMap{ String($0.count) } ?? ""
        }
    }
}
