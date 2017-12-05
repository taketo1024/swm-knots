//
//  CellularComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/26.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias CellularChain<R: Ring> = FreeModule<CellularCell, R>

public struct CellularCell: GeometricCell {
    public let simplices: [Simplex]
    internal let boundary: CellularChain<IntegerNumber>
    
    internal init(_ simplices: [Simplex], _ boundary: CellularChain<IntegerNumber>) {
        assert(!simplices.isEmpty)
        assert({
            let n = simplices.anyElement!.dim
            return simplices.forAll{$0.dim == n}
        }())
        
        self.simplices = simplices
        self.boundary = boundary
    }
    
    public var dim: Int {
        return simplices.anyElement!.dim
    }
    
    public var hashValue: Int {
        return 0 // TODO
    }
    
    public static func ==(a: CellularCell, b: CellularCell) -> Bool {
        return a.simplices == b.simplices
    }
    
    public var description: String {
        return "e\(simplices)"
    }
}

public struct CellularComplex: GeometricComplex {
    public typealias Cell = CellularCell
    
    public internal(set) var underlyingComplex: SimplicialComplex
    internal var cells: [[CellularCell]]
    
    public init(underlyingComplex: SimplicialComplex) {
        self.init(underlyingComplex, [])
    }
    
    internal init(_ K: SimplicialComplex, _ cells: [[CellularCell]] = []) {
        self.underlyingComplex = K
        self.cells = cells
    }
    
    public var dim: Int {
        return max(0, cells.count - 1)
    }
    
    public func skeleton(_ dim: Int) -> CellularComplex {
        let sub = Array(cells[0 ... dim])
        return CellularComplex(underlyingComplex, sub)
    }
    
    public func cells(ofDim i: Int) -> [CellularCell] {
        return (0...dim).contains(i) ? cells[i] : []
    }
    
    public func boundary<R: Ring>(ofCell s: CellularCell, _ type: R.Type) -> FreeModule<CellularCell, R> {
        return s.boundary.mapValues{ R(intValue: $0) }
    }
    
    @discardableResult
    public mutating func appendVertex(_ v: Vertex) -> CellularCell {
        return appendCell( simplices: [Simplex(v)] )
    }
    
    @discardableResult
    public mutating func appendCell(simplices: [Simplex], attachedAlong boundary: CellularChain<IntegerNumber> = CellularChain.zero) -> CellularCell {
        if !simplices.forAll({ underlyingComplex.contains($0) }) {
            let K = SimplicialComplex( maximalCells: simplices )
            self.underlyingComplex = self.underlyingComplex + K
        }
        
        let n = simplices.anyElement!.dim
        assert(boundary.basis.forAll{ $0.dim == n - 1 }, "only attatching to 1-dim lower cells is supported.")
        
        while cells.count - 1 < n {
            cells.append([])
        }
        
        let cell = CellularCell(simplices, boundary)
        cells[n].append(cell)
        
        return cell
    }
}

public extension CellularComplex {
    static func point() -> CellularComplex {
        let K = SimplicialComplex.point()
        var C = CellularComplex(underlyingComplex: K)
        C.appendVertex(K.vertices[0])
        return C
    }

    static func interval(vertices n: Int = 2) -> CellularComplex {
        let K = SimplicialComplex.interval(vertices: n)
        var C = CellularComplex(underlyingComplex: K)
        let v0 = C.appendVertex(K.vertices[0])
        let v1 = C.appendVertex(K.vertices[n - 1])
        C.appendCell(simplices: K.cells(ofDim: 1), attachedAlong: CellularChain([(v1, 1), (v0, -1)]))
        return C
    }
    
    static func circle() -> CellularComplex {
        return CellularComplex.sphere(dim: 1)
    }
    
    static func sphere(dim i: Int) -> CellularComplex {
        fatalError("TBD")
    }
    
    static func ball(dim: Int) -> CellularComplex {
        fatalError("TBD")
    }
    
    static func torus(dim: Int) -> SimplicialComplex {
        fatalError("TBD")
    }
}

