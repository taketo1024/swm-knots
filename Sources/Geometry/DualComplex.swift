//
//  DualComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/15.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct DualSimplicialCell: Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    public let dim: Int
    public let base: Simplex
    public let center: Vertex
    public let chain: SimplicialChain<IntegerNumber> // chain of SdK
    
    public init(dim: Int, base: Simplex, center: Vertex, chain: SimplicialChain<IntegerNumber>) {
        self.dim = dim
        self.base = base
        self.center = center
        self.chain = chain
    }
    
    public init(dim: Int, base: Simplex, center: Vertex, components: [Simplex]) {
        let chain = { () -> SimplicialChain<IntegerNumber> in
            if dim > 1 {
                let V  = center.vertexSet // VSet of SdK
                let St = SimplicialComplex(V, components)
                let Lk = SimplicialComplex(V, St.link(center), generate: true) // TODO no need to generate all
                
                // Lk ~ S^{dim - 1}
                let H  = HomologyGroupInfo(Lk.chainComplex(type: IntegerNumber.self), degree: Lk.dim)
                guard H.rank == 1 else {
                    fatalError("invalid dual-cell. center: \(center), components: \(components)")
                }
                
                let z = H.summands[0].generator
                return center.join(z)
                
            } else if dim == 1 {
                guard components.count == 2 else {
                    fatalError("invalid dual-cell. center: \(center), components: \(components)")
                }
                
                let pts = components.map{ $0.subtract(center) } // two boundary pts
                let z = SimplicialChain<IntegerNumber>(basis: pts, components: [-1, 1])
                return center.join(z)
                
            } else {
                return FreeModule(components[0])
            }
        }()
        
        self.init(dim: dim, base: base, center: center, chain: chain)
    }
    
    public var hashValue: Int {
        return base.hashValue
    }
    
    public var description: String {
        return "d\(base)"
    }
    
    public var debugDescription: String {
        return "d\(base) : \(chain)"
    }
    
    public static func ==(a: DualSimplicialCell, b: DualSimplicialCell) -> Bool {
        return a.base == b.base
    }
}

public final class DualSimplicialComplex: GeometricComplex {
    public typealias Cell = DualSimplicialCell
    
    public let dim: Int
    public let baseComplex: SimplicialComplex
    public let barycentricSubdivision: SimplicialComplex
    internal let cellList: [[Cell]] // [0: [0-dim cells], 1: [1-dim cells], ...]
    
    // root initializer
    public init(_ baseComplex: SimplicialComplex, _ barycentricSubdivision: SimplicialComplex, _ cells: [[Cell]]) {
        self.dim = cells.count - 1
        self.baseComplex = baseComplex
        self.barycentricSubdivision = barycentricSubdivision
        self.cellList = cells
    }
    
    public convenience init(_ baseComplex: SimplicialComplex) {
        let K = baseComplex
        let n = K.dim
        
        let SdK = K.barycentricSubdivision()
        let SdV = SdK.vertexSet
        
        let cells = (0 ... n).reversed().map { (i) -> [DualSimplicialCell] in
            let bcells = SdK.allCells(ofDim: n - i) // comps of dual-cells, codim: i
            
            return K.allCells(ofDim: i).map { (s: Simplex) -> DualSimplicialCell in
                let b = SdV.barycenterOf(s)!
                let comps = bcells.filter{ (bcell) in
                    bcell.contains(b)
                        && bcell.vertices.forAll{ SdV.simplex(forBarycenter: $0)!.contains(s) }
                }
                return DualSimplicialCell(dim: n - i, base: s, center: b, components: comps)
            }
        }
        self.init(K, SdK, cells)
    }
    
    public func skeleton(_ dim: Int) -> DualSimplicialComplex {
        let sub = Array(cellList[0 ... dim])
        return DualSimplicialComplex(baseComplex, barycentricSubdivision, sub)
    }
    
    public func allCells(ofDim i: Int) -> [DualSimplicialCell] {
        return (0...dim).contains(i) ? cellList[i] : []
    }
    
    public func boundary<R: Ring>(ofCell s: DualSimplicialCell) -> FreeModule<DualSimplicialCell, R> {
        let z = s.chain.boundary()
        let dCells = allCells(ofDim: s.dim - 1)
        
        let pairs = baseComplex.cofaces(ofCell: s.base).map{ (t: Simplex) -> (DualSimplicialCell, R) in
            let b = barycentricSubdivision.vertexSet.barycenterOf(t)!
            let dCell = dCells.first{ $0.center == b}!
            
            let t0 = dCell.chain.basis[0] // take any simplex to detect orientation
            let e = (dCell.chain[t0] == z[t0]) ? 1 : -1
            
            return (dCell, R(intValue: e))
        }
        
        return FreeModule(pairs)
    }
}

