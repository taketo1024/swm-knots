//
//  ExactSequence.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/12/14.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct ExactSequence<R: EuclideanRing>: Sequence {
    public typealias Object = AbstractSimpleModuleStructure<R>
    public typealias Arrow  = FreeModuleHom<Int, Int, R>
    
    internal var objects: [Object?]
    public   var arrows : Arrows
    
    public init(objects: [Object?], arrows: [Arrow?]) {
        assert(objects.count - 1 == arrows.count)
        self.objects = objects
        self.arrows  = Arrows(arrows)
    }

    public init(count n: Int) {
        self.init(objects: Array(repeating: nil, count: n), arrows: Array(repeating: nil, count: n - 1))
    }
    
    public var length: Int {
        return objects.count
    }
    
    public subscript(i: Int) -> Object? {
        get {
            return (0 ..< length).contains(i) ? objects[i] : Object.zeroModule
        } set {
            if (0 ..< length).contains(i) {
                objects[i] = newValue
                
                if let o = newValue, o.isTrivial {
                    arrows[i - 1] = Arrow.zero
                    arrows[i]     = Arrow.zero
                }
            }
        }
    }
    
    public struct Arrows {
        internal var arrows: [Arrow?]
        internal init (_ arrows: [Arrow?]) {
            self.arrows = arrows
        }
        
        public subscript(i: Int) -> Arrow? {
            get {
                return (0 ..< arrows.count).contains(i) ? arrows[i] : Arrow.zero
            } set {
                if (0 ..< arrows.count).contains(i) {
                    arrows[i] = newValue
                }
            }
        }
    }
    
    public func matrix(_ i: Int) -> ComputationalMatrix<R>? {
        guard
            let from = self[i],
            let to   = self[i + 1],
            let map  = arrows[i]
            else { return nil }
        
        let comps = from.generators.enumerated().flatMap { (j, z) -> [MatrixComponent<R>] in
            let w = map.appliedTo(z)
            let vec = to.factorize(w)
            return vec.enumerated().map{ (i, a) in (i, j, a) }
        }
        
        return ComputationalMatrix(rows: to.generators.count, cols: from.generators.count, components: comps)
    }
    
    public func assertExactness(at i1: Int, debug d: Bool = false) {
        
        //     f0        f1
        // M0 ---> [M1] ---> M2
        
        let (i0, i2) = (i1 - 1, i1 + 1)
        
        guard
            let M0 = self[i0],
            let M1 = self[i1],
            let M2 = self[i2],
            let f0 = arrows[i0],
            let f1 = arrows[i1]
            else {
                log("\(i1): skipped.", d)
                return
        }
        
        log("\(i1): \(M0) -> [\(M1)] -> \(M2)", d)
        
        if M1.isTrivial {
            return
        }
        
        // Im ⊂ Ker
        for x in M0.generators {
            let y = f0.appliedTo(x)
            let z = f1.appliedTo(y)
            
            log("\t\(x) ->\t\(y) ->\t\(z)", d)
            assert(M2.elementIsZero(z))
        }
        
        // Im ⊃ Ker
        // TODO
    }
    
    public func assertExactness(debug: Bool = false) {
        for i in 0 ..< length {
            assertExactness(at: i, debug: debug)
        }
    }
    
    @discardableResult
    public mutating func solve(_ i: Int, debug d: Bool = false) -> Object? {
        if let o = self[i] {
            return o
        }
        
        if let o = _solve(i) {
            self[i] = o
            return o
        } else {
            return nil
        }
    }
    
    private func _solve(_ i2: Int, debug d: Bool = false) -> Object? {
        
        // Aim: [M2]
        //
        //     f0      f1        f2      f3
        // M0 ---> M1 ---> [M2] ---> M3 ---> M4  (exact)
        //
        
        guard
            let M1 = self[i2 - 1],
            let M3 = self[i2 + 1]
            else {
                return nil
        }
        
        // Case 1.
        // 0 -> [M2] -> 0  ==>  M2 = 0
        
        if M1.isTrivial && M3.isTrivial {
            return Object.zeroModule
        }
        
        // Case 2.
        // 0 -> M1 -> [M2] -> 0  ==>  M1 ~= M2
        
        if let M0 = self[i2 - 2], M0.isTrivial && M3.isTrivial {
            return M1
        }
        
        // Case 3.
        // 0 -> [M2] -> M3 -> 0  ==>  M2 ~= M3
        
        if let M4 = self[i2 + 2], M1.isTrivial && M4.isTrivial {
            return M3
        }
        
        // General Case.
        //
        //     f0      f1        f2      f3
        // M0 ---> M1 ---> [M2] ---> M3 ---> M4  (exact)
        //
        // ==>
        //               i         f2
        // 0 -> Ker(f2) >--> [M2] -->> Im(f2) -> 0  (exact)
        //       = Im(f1)               = Ker(f3)
        //      ~= Coker(f0)
        
        // TODO
        return nil
    }
    
    @discardableResult
    public mutating func solveAll(debug: Bool = false) -> [Object?] {
        return (0 ..< length).map{ i in solve(i, debug: debug) }
    }
    
    public func makeIterator() -> AnyIterator<Object?> {
        let lazy = (0 ..< length).lazy.map{ k in self[k] }
        return AnyIterator(lazy.makeIterator())
    }
    
    public var description: String {
        return "ExactSequence(length: \(length))"
    }
    
    public var detailDescription: String {
        return "\(self.description)\n--------------------\n0\t-> "
            + objects.map{ $0.flatMap{"\($0)"} ?? "?" }.joined(separator: "\t-> ")
            + "\t-> 0"
    }
}
