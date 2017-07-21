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
    
    public init(dim: Int, base: Simplex, center: Vertex, components: [Simplex]) {
        self.dim = dim
        self.base = base
        self.center = center
        
        self.chain = { () -> SimplicialChain<IntegerNumber> in
            if dim > 1 {
                let V  = center.vertexSet // VSet of SdK
                let St = SimplicialComplex(V, components)
                let Lk = SimplicialComplex(V, St.link(center), generate: true) // TODO no need to generate all
                
                // Lk ~ S^{dim - 1}
                let H  = HomologyGroupInfo(Lk.chainComplex(type: IntegerNumber.self), dim: Lk.dim)
                guard H.rank == 1 else {
                    fatalError("invalid star \(center) : \(components)")
                }
                
                let z = H.summands[0].generator
                return center.join(z)
                
            } else if dim == 1 {
                guard components.count == 2 else {
                    fatalError("invalid star \(center) : \(components)")
                }
                
                let pts = components.map{ $0.subtract(center) } // two boundary pts
                let z = SimplicialChain<IntegerNumber>(basis: pts, components: [-1, 1])
                return center.join(z)
                
            } else {
                return FreeModule(components[0])
            }
        }()
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

public final class DualSimplicialComplex: GeometricComplex, CustomStringConvertible, CustomDebugStringConvertible {
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
        let SdK = K.barycentricSubdivision()
        let n = K.dim
        
        let cells = (0 ... n).reversed().map { (i) -> [DualSimplicialCell] in
            return K.allCells(ofDim: i).map { (s0: Simplex) -> DualSimplicialCell in
                let b0 = SdK.vertexSet.barycenterOf(s0)!
                
                let star   = K.star(s0)
                let bcells = SdK.allCells(ofDim: n - i) // comps of dual-cells, codim: i
                
                // take all cells in SdK that contain both bcenters of s and t.
                let comps = star.flatMap{ (s1: Simplex) -> [Simplex] in
                    let b1 = SdK.vertexSet.barycenterOf(s1)!
                    return bcells.filter{ $0.contains(b0) && $0.contains(b1) }
                }
                
                return DualSimplicialCell(dim: n - i, base: s0, center: b0, components: comps)
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
    
    public func boundary<R: Ring>(ofCell s: Cell) -> [(Cell, R)] {
        fatalError()
    }
    
    public var description: String {
        return "DualComplex"
    }
    
    public var debugDescription: String {
        return "DualComplex:{\n\t" + cellList.map{ (cells) in cells.map{$0.debugDescription}.joined(separator: ",\n\t")}.joined(separator: ",\n\n\t") + "\n}"
    }
}

