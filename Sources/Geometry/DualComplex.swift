//
//  DualComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/15.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct DualCell: Hashable, CustomStringConvertible, CustomDebugStringConvertible {
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
    
    public static func ==(a: DualCell, b: DualCell) -> Bool {
        return a.base.id == b.base.id
    }
}

public struct DualComplex: GeometricComplex, CustomStringConvertible, CustomDebugStringConvertible {
    public let dim: Int
    public let baseComplex: SimplicialComplex
    public let cellList: [[DualCell]] // [0: [0-dim blocks], 1: [1-dim-blocks], ...]
    
    // root initializer
    public init(_ baseComplex: SimplicialComplex, _ cells: [[DualCell]]) {
        self.dim = cells.count - 1
        self.baseComplex = baseComplex
        self.cellList = cells
    }
    
    public init(_ baseComplex: SimplicialComplex) {
        let K = baseComplex
        let SdK = K.barycentricSubdivision()
        
        let cells = (0 ... K.dim).reversed().map { (i) -> [DualCell] in
            let bcells = SdK.cells(K.dim - i) // comps of dual-cells, codim: i
            return K.simplices(i).map { (s: Simplex) -> DualCell in
                let v0 = SdK.vertexSet.barycenterOf(s)!
                let tops = K.facets.filter{ $0.contains(s) }
                
                // take all cells in SdK that contain both bcenters of s and t.
                let comps = tops.flatMap{ (top: Simplex) -> [Simplex] in
                    let v1 = SdK.vertexSet.barycenterOf(top)!
                    return bcells.filter{ $0.contains(v0) && $0.contains(v1) }
                }

                return DualCell(s, comps)
            }
        }
        self.init(baseComplex, cells)
    }
    
    public func skeleton(_ dim: Int) -> DualComplex {
        let sub = Array(cellList[0 ... dim])
        return DualComplex(baseComplex, sub)
    }
    
    public func cells(_ i: Int) -> [DualCell] {
        return (0...dim).contains(i) ? cellList[i] : []
    }
    
    public func boundaryMapMatrix<R: Ring>(_ from: [DualCell], _ to : [DualCell]) -> DynamicMatrix<R> {
        fatalError() // TODO
    }
    
    public var description: String {
        return "DualComplex"
    }
    
    public var debugDescription: String {
        return "DualComplex:{\n\t" + cellList.map{ (cells) in cells.map{$0.debugDescription}.joined(separator: ",\n\t")}.joined(separator: ",\n\n\t") + "\n}"
    }
}

