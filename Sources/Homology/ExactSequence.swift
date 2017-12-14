//
//  ExactSequence.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/12/14.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct ExactSequence<A: FreeModuleBase, R: EuclideanRing>: Sequence {
    public typealias Object = SimpleModuleStructure<A, R>
    public typealias Arrow  = FreeModuleHom<A, A, R>
    
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
    
    public func assertExactness(at i: Int, debug: Bool = false) {
        
        //     f0        f1
        // M0 ---> [M1] ---> M2

        guard
            let M0 = self[i - 1],
            let M1 = self[i],
            let M2 = self[i + 1],
            let f0 = arrows[i],
            let f1 = arrows[i + 1]
            else {
                debugLog("\(i): Assertion passed.\n")
                return
        }
        
        if M1.isTrivial {
            debugLog("\(i): Trivial.\n")
            return
        }
        
        debugLog(print: debug, "\(i): \(M0) -> \(M1) -> \(M2)")
        
        // Im ⊂ Ker
        for x in M0.generators {
            let y = f0.appliedTo(x)
            let z = f1.appliedTo(y)
            
            debugLog(print: debug, "\t\(x) ->\t\(y) ->\t\(z)")
            assert(M2.elementIsZero(z))
        }
        
        // Im ⊃ Ker
        // TODO
        
        debugLog(print: debug, "\n")
    }
    
    public func assertExactness(debug: Bool = false) {
        for i in 0 ..< length {
            assertExactness(at: i)
        }
    }
    
    @discardableResult
    public mutating func solve(_ i: Int) -> Object? {
        //     f0      f1        f2      f3
        // M0 ---> M1 ---> [M2] ---> M3 ---> M4  (exact)
        //
        // ==>
        //               i         f2
        // 0 -> Ker(f2) >--> [M2] -->> Im(f2) -> 0  (exact)
        //       = Im(f1)               = Ker(f3)
        //      ~= Coker(f0)
        
        guard
            let M1 = self[i - 1],
            let M3 = self[i + 1]
            else {
                return nil
        }
        
        // Case 1.
        // 0 -> M2 -> 0  ==>  M2 = 0
        
        if M1.isTrivial && M3.isTrivial {
            let M2 = Object.zeroModule
            self[i] = M2
            return M2
        }
        
        // Case 2.
        // 0 -> M1 -> M2 -> 0  ==>  M1 ~= M2
        
        if let M0 = self[i - 2], M0.isTrivial && M3.isTrivial {
            // TODO
            return nil
        }

        return nil
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
