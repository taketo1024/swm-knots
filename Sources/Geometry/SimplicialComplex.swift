//
//  SimplicialComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/17.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct SimplicialComplex: GeometricComplex {
    public typealias Cell = Simplex
    
    public var name: String
    internal let table: [[Simplex]]
    
    // root initializer
    internal init(name: String? = nil, table: [[Simplex]]) {
        self.name = name ?? "_"
        
        if let l = table.last, l.isEmpty {
            let n = table.reversed().index{ l in !l.isEmpty }.map{ Int($0) } ?? table.count
            self.table = table.dropLast(n).toArray()
        } else {
            self.table = table
        }
    }
    
    public init<S: Sequence>(name: String? = nil, allCells cells: S) where S.Iterator.Element == Simplex {
        self.init(name: name, table: SimplicialComplex.alignCells(cells, generateFaces: false))
    }
    
    public init(name: String? = nil, allCells cells: Simplex...) {
        self.init(name: name, allCells: cells)
    }
    
    public init<S: Sequence>(name: String? = nil, maximalCells cells: S) where S.Iterator.Element == Simplex {
        self.init(name: name, table: SimplicialComplex.alignCells(cells, generateFaces: true))
    }
    
    public init(name: String? = nil, maximalCells cells: Simplex...) {
        self.init(name: name, maximalCells: cells)
    }
    
    public static var empty: SimplicialComplex {
        return SimplicialComplex.init(name: "∅", table: [])
    }
    
    public var dim: Int {
        return table.count - 1
    }
    
    public func skeleton(_ n: Int) -> SimplicialComplex {
        if n >= 0 {
            let sub = table[0 ... n].toArray()
            return SimplicialComplex(name: "\(self.name)_(\(n))", table: sub)
        } else {
            return SimplicialComplex.empty
        }
    }
    
    public func cells(ofDim i: Int) -> [Simplex] {
        return validDims.contains(i) ? table[i] : []
    }
    
    public var vertices: [Vertex] {
        return (dim >= 0) ? table[0].map{ $0.vertices[0] } : []
    }
    
    private var _maximalCells: Cache<[Simplex]> = Cache()
    
    public var maximalCells: [Simplex] {
        if let cells = _maximalCells.value {
            return cells
        }
        
        var cells = table.reversed().joined().toArray()
        var i = 0
        while i < cells.count {
            let s = cells[i]
            let subs = s.allSubsimplices().dropFirst()
            for t in subs {
                if let j = cells.index(of: t) {
                    cells.remove(at: j)
                }
            }
            i += 1
        }
        
        _maximalCells.value = cells
        return cells
    }
    
    public func cofaces(ofCell s: Simplex) -> [Simplex] {
        return cells(ofDim: s.dim + 1).filter{ $0.contains(s) }
    }
    
    public func named(_ name: String) -> SimplicialComplex {
        var K = self
        K.name = name
        return K
    }
    
    internal static func alignCells<S: Sequence>(_ cells: S, generateFaces gFlag: Bool) -> [[Simplex]] where S.Iterator.Element == Simplex {
        let dim = cells.reduce(-1) { max($0, $1.dim) }
        if dim < 0 {
            return []
        }
        
        let set: Set<Simplex>
        if gFlag {
            set = cells.reduce( Set<Simplex>() ){ (set, cell) in
                set.union( cell.allSubsimplices() )
            }
        } else {
            set = Set(cells)
        }
        
        var cells: [[Simplex]] = (0 ... dim).map{_ in []}
        for s in set {
            cells[s.dim].append(s)
        }
        
        return cells.map { list in list.sorted() }
    }
}
