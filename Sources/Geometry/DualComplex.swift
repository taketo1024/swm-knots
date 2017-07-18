//
//  DualComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/15.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct DualSimplicialCell: Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    public let base: Simplex
    public let components: [Simplex]
    
    public init(_ base: Simplex, _ components: [Simplex]) {
        self.base = base
        self.components = components
    }
    
    public var hashValue: Int {
        return 0 // TODO
    }
    
    public var description: String {
        return "d\(base)"
    }
    
    public var debugDescription: String {
        return "d\(base) : \(components)"
    }
    
    public static func ==(a: DualSimplicialCell, b: DualSimplicialCell) -> Bool {
        return a.base == b.base
    }
}

public final class DualSimplicialComplex: GeometricComplex, CustomStringConvertible, CustomDebugStringConvertible {
    public typealias Cell = DualSimplicialCell
    
    public let dim: Int
    public let baseComplex: SimplicialComplex
    internal let cellList: [[Cell]] // [0: [0-dim cells], 1: [1-dim cells], ...]
    
    // root initializer
    public init(_ baseComplex: SimplicialComplex, _ cells: [[Cell]]) {
        self.dim = cells.count - 1
        self.baseComplex = baseComplex
        self.cellList = cells
    }
    
    public convenience init(_ baseComplex: SimplicialComplex) {
        let K = baseComplex
        let SdK = K.barycentricSubdivision()
        
        let cells = (0 ... K.dim).reversed().map { (i) -> [DualSimplicialCell] in
            let bcells = SdK.allCells(ofDim: K.dim - i) // comps of dual-cells, codim: i
            return K.allCells(ofDim: i).map { (s: Simplex) -> DualSimplicialCell in
                let v0 = SdK.vertexSet.barycenterOf(s)!
                
                // take all cells in SdK that contain both bcenters of s and t.
                let comps = K.star(s).flatMap{ (t: Simplex) -> [Simplex] in
                    let v1 = SdK.vertexSet.barycenterOf(t)!
                    return bcells.filter{ $0.contains(v0) && $0.contains(v1) }
                }

                return DualSimplicialCell(s, comps)
            }
        }
        self.init(baseComplex, cells)
    }
    
    public func skeleton(_ dim: Int) -> DualSimplicialComplex {
        let sub = Array(cellList[0 ... dim])
        return DualSimplicialComplex(baseComplex, sub)
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

