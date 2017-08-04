//
//  DualComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/15.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct DualSimplicialCell: GeometricCell {
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
                let Lk = SimplicialComplex(maximalCells: components.map{$0.subtract(center)}, lowerBound: dim - 2)
                
                guard let z = Lk.preferredOrientation() else {
                    fatalError("invalid dual-cell. center: \(center), components: \(components)")
                }
                
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
    
    public var detailDescription: String {
        return "d\(base) : \(chain)"
    }
    
    public static func ==(a: DualSimplicialCell, b: DualSimplicialCell) -> Bool {
        return a.base == b.base
    }
}

public struct DualSimplicialComplex: GeometricComplex {
    public typealias Cell = DualSimplicialCell
    
    internal let K: SimplicialComplex
    internal let SdK: BarycentricSubdivision
    internal let cells: [[Cell]] // [0: [0-dim cells], 1: [1-dim cells], ...]
    
    // root initializer
    public init(_ K: SimplicialComplex, _ SdK: BarycentricSubdivision, _ cells: [[Cell]]) {
        self.K = K
        self.SdK = SdK
        self.cells = cells
    }
    
    public init(_ K: SimplicialComplex) {
        let n = K.dim
        let SdK = K.barycentricSubdivision()
        
        let cells = (0 ... n).reversed().map { (i) -> [DualSimplicialCell] in
            let bcells = SdK.allCells(ofDim: n - i) // comps of dual-cells, codim: i
            
            return K.allCells(ofDim: i).map { (s: Simplex) -> DualSimplicialCell in
                let b = SdK.barycenterOf(s)!
                let comps = bcells.filter{ (bcell) in
                    bcell.contains(b)
                        && bcell.vertices.forAll{ SdK.simplex(forBarycenter: $0)!.contains(s) }
                }
                return DualSimplicialCell(dim: n - i, base: s, center: b, components: comps)
            }
        }
        self.init(K, SdK, cells)
    }
    
    public var dim: Int {
        return K.dim
    }
    
    public func skeleton(_ dim: Int) -> DualSimplicialComplex {
        let sub = Array(cells[0 ... dim])
        return DualSimplicialComplex(K, SdK, sub)
    }
    
    public func allCells(ofDim i: Int) -> [DualSimplicialCell] {
        return (0...dim).contains(i) ? cells[i] : []
    }
    
    public func boundary<R: Ring>(ofCell s: DualSimplicialCell) -> FreeModule<R, DualSimplicialCell> {
        let z = s.chain.boundary()
        let dCells = allCells(ofDim: s.dim - 1)
        
        let elements = K.cofaces(ofCell: s.base).map{ (t: Simplex) -> (R, DualSimplicialCell) in
            let b = SdK.barycenterOf(t)!
            let dCell = dCells.first{ $0.center == b}!
            
            let t0 = dCell.chain.basis[0] // take any simplex to detect orientation
            let e = R(intValue: (dCell.chain[t0] == z[t0]) ? 1 : -1)
            
            return (e, dCell)
        }
        
        return FreeModule(elements)
    }
}

public extension SimplicialComplex {
    public func dualComplex() -> DualSimplicialComplex {
        return DualSimplicialComplex(self)
    }
}
