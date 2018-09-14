//
//  KnotFloerChainComplex.swift
//  Sample
//
//  Created by Taketo Sano on 2018/09/13.
//

import SwiftyMath
import SwiftyHomology

public struct CFKTilde {
    public typealias R = 𝐙₂
    public typealias A = GridDiagram.Generator
    
    public let gridDiagram: GridDiagram
    public let chainComplex: ChainComplex<A, R>
    
    public init(_ G: GridDiagram) {
        self.gridDiagram = G
        self.chainComplex = { () -> ChainComplex<A, R> in
            let OXs = G.Os + G.Xs
            
            let gens = G.generators.group{ x in G.MaslovGrading(x) }
            let base = ModuleGrid1<A, R>(name: "CFK~", generators: gens)
            
            let d = ChainMap<A, A, R>(degree: -1) { i in
                FreeModuleHom{ (x: A) -> FreeModule<A, R> in
                    let ys = base[i - 1]!.generators.map{ $0.basis.anyElement! }
                    return ys.map { y in
                        let rs = G.emptyRectangles(from: x, to: y)
                        let a = rs.count { r in
                            !r.contains(OXs, gridSize: G.gridSize)
                        }
                        return R(from: a) * .wrap(y)
                    }.sumAll()
                }
            }
            
            return ChainComplex(base: base, differential: d)
        }()
    }
    
    public func describe(_ i: Int) {
        chainComplex.describe(i)
    }
    
    public func describeAll() {
        chainComplex.describeAll()
    }

    public func assertChainComplex(debug: Bool = false) {
        chainComplex.assertChainComplex(debug: debug)
    }
    
    public func homology() -> ModuleGrid1<A, R> {
        return chainComplex.homology()
    }
}
