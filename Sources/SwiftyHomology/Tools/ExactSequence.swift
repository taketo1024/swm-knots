//
//  ExactSequence.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/12/14.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation
import SwiftyMath

public extension LogFlag {
    public static var exactSequence: LogFlag {
        return LogFlag(id: "Homology.ExactSequence", label: "exSeq")
    }
}

public struct ExactSequence<R: EuclideanRing>: Sequence {
    public typealias Object = AbstractSimpleModuleStructure<R>
    public typealias Map    = FreeModuleHom<AbstractBasisElement, AbstractBasisElement, R>
    
    internal var objects: [Object?]
    internal var arrows : Arrows
    
    public init(objects: [Object?], maps: [Map?]) {
        assert(objects.count - 1 == maps.count)
        self.objects = objects
        self.arrows  = Arrows(maps)
    }

    public init(count n: Int) {
        self.init(objects: Array(repeating: nil, count: n), maps: Array(repeating: nil, count: n - 1))
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
    
    public func map(_ i: Int) -> Map? {
        return arrows[i].map
    }
    
    public func matrix(_ i: Int) -> Matrix<R>? {
        guard
            let from = self[i],
            let to   = self[i + 1],
            let map  = arrows[i].map
            else { return nil }
        
        let comps = from.generators.enumerated().flatMap { (j, z) -> [MatrixComponent<R>] in
            let w = map.applied(to: z)
            let vec = to.factorize(w)
            return vec.enumerated().map{ (i, a) in MatrixComponent(i, j, a) }
        }
        
        return Matrix(rows: to.generators.count, cols: from.generators.count, components: comps)
    }
    
    public func isZero(_ i: Int) -> Bool {
        return self[i]?.isTrivial ?? false
    }
    
    public func isNonZero(_ i: Int) -> Bool {
        return self[i].map{ !$0.isTrivial } ?? false
    }
    
    public func isZeroMap(_ i1: Int) -> Bool {
        if self.arrows[i1].isZero {
            return true
        }
        
        let (i0, i2, i3) = (i1 - 1, i1 + 1, i1 + 2)
        
        if let M1 = self[i1], M1.isTrivial {
            return true
        }
        
        if let M2 = self[i2], M2.isTrivial {
            return true
        }
        
        if let A1 = matrix(i1), A1.isZero {
            return true
        }
        
        if  let M2 = self[i2], M2.isFree,
            let M3 = self[i3], M3.isFree,
            let A2 = matrix(i2), A2.elimination().isInjective {
            return true
        }
        
        if  let M0 = self[i0], M0.isFree,
            let M1 = self[i1], M1.isFree,
            let A0 = matrix(i0), A0.elimination().isSurjective {
            return true
        }
        
        return false
    }
    
    public func isInjective(_ i: Int) -> Bool {
        return isZeroMap(i - 1)
    }
    
    public func isSurjective(_ i: Int) -> Bool {
        return isZeroMap(i + 1)
    }
    
    public func isIsomorphic(_ i: Int) -> Bool {
        return isInjective(i) && isSurjective(i)
    }
    
    public mutating func solve() {
        return (0 ..< length).forEach{ i in solve(i) }
    }
    
    @discardableResult
    public mutating func solve(_ i: Int) -> Object? {
        if let o = self[i] {
            return o
        }
        
        if let o = solveObject(i) {
            self[i] = o
            return o
        } else {
            return nil
        }
    }
    
    internal mutating func solveObject(_ i2: Int) -> Object? {
        
        // Aim: [M2]
        //
        //     f0      f1        f2      f3
        // M0 ---> M1 ---> [M2] ---> M3 ---> M4  (exact)
        //
        
        let (i0, i1, i3) = (i2 - 2, i2 - 1, i2 + 1)
        
        // Case 1.
        //
        //     0         0
        // M1 ---> [M2] ---> M3  ==>  M2 = Ker(0) = Im(0) = 0
        
        if solveZeroMap(i1), solveZeroMap(i2) {
            log("\(i2): trivial.")
            return Object.zeroModule
        }
        
        // Case 2.
        //
        //     0       f1        0
        // M0 ---> M1 ---> [M2] ---> M3  ==>  f1: isom
        
        if let M1 = self[i1], solveZeroMap(i0), solveZeroMap(i2) {
            log("\(i2): isom to \(i1).")
            arrows[i1] = Arrow.identity
            return M1
        }
        
        // Case 3.
        //
        //     0         f2      0
        // M1 ---> [M2] ---> M3 ---> M4  ==>  f2: isom
        
        if let M3 = self[i3], solveZeroMap(i1), solveZeroMap(i3) {
            log("\(i2): isom to \(i3).")
            arrows[i2] = Arrow.identity
            return M3
        }
        
        // General Case.
        //
        //     f0      f1        f2      f3
        // M0 ---> M1 ---> [M2] ---> M3 ---> M4  (exact)
        //
        // ==>
        //                       f2
        // 0 -> Ker(f2) ⊂  [M2] -->> Im(f2) -> 0  (exact)
        //       = Im(f1)             = Ker(f3)
        //      ~= Coker(f0)
        
        guard
            let M1 = self[i1], M1.isFree, // TODO concider non-free case
            let M3 = self[i3], M3.isFree,
            let A0 = matrix(i0),
            let A3 = matrix(i3)
            else {
                log("\(i2): unsolvable.")
                return nil
        }
        
        let N0 = AbstractSimpleModuleStructure(generators: AbstractBasisElement.generateBasis(M1.rank), relationMatrix: A0)
        let N1 = AbstractSimpleModuleStructure<R>(rank: A3.elimination().nullity)
        
        log("\(i2): \(N0) ⊕ \(N1)")
        
        return N0 ⊕ N1
    }
    
    //  The following are equivalent:
    //
    //        f0     [f1]      f2
    //    M0 ---> M1 ----> M2 ---> M3
    //
    //
    //  1) f1 = 0
    //  2) f2: injective  ( Ker(f2) = Im(f1) = 0 )
    //  3) f0: surjective ( M1 = Ker(f1) = Im(f0) )
    //
    
    internal mutating func solveZeroMap(_ i1: Int) -> Bool {
        if isZeroMap(i1) {
            self.arrows[i1].isZero = true
            return true
        } else {
            return false
        }
    }
    
    public func describe(_ i0: Int) {
        let i1 = i0 + 1
        print("\(objectDescription(i0)) \(arrowDescription(i0)) \(objectDescription(i1))", "\n")
        
        for i in [i0, i1] {
            if let M = self[i] {
                print(M, "{")
                for x in M.generators {
                    print("\t", x)
                }
                print("}\n")
            }
        }
        
        if let A = self.matrix(i0) {
            print(A.detailDescription, "\n")
        }
    }
    
    public func assertExactness(at i1: Int) {
        
        //     f0        f1
        // M0 ---> [M1] ---> M2
        
        let (i0, i2) = (i1 - 1, i1 + 1)
        
        guard
            let M0 = self[i0],
            let M1 = self[i1],
            let M2 = self[i2],
            let f0 = arrows[i0].map,
            let f1 = arrows[i1].map
            else {
                return
        }
        
        if M1.isTrivial {
            return
        }
        
        // Im ⊂ Ker
        for x in M0.generators {
            let y = f0.applied(to: x)
            let z = f1.applied(to: y)
            
            assert(M2.elementIsZero(z))
        }
        
        // Im ⊃ Ker
        // TODO
    }
    
    public func assertExactness() {
        for i in 0 ..< length {
            assertExactness(at: i)
        }
    }
    
    public func makeIterator() -> AnyIterator<Object?> {
        let lazy = (0 ..< length).lazy.map{ k in self[k] }
        return AnyIterator(lazy.makeIterator())
    }
    
    internal func objectDescription(_ i: Int) -> String {
        return self[i]?.description ?? "?"
    }
    
    internal func arrowDescription(_ i: Int) -> String {
        return isNonZero(i) && isNonZero(i + 1)
                ? (isZeroMap(i) ? "-ͦ>" : isIsomorphic(i) ? "-̃>" : isInjective(i) ? "-ͫ>" : isSurjective(i) ? "-ͤ>" : "->")
                : "->"
    }
    
    public var description: String {
        return "ExSeq<\(R.symbol)>: "
            + "0 -> "
            + (0 ..< length).map { i in "\(objectDescription(i)) \(arrowDescription(i)) " }.joined()
            + "0"
    }
    
    private func log(_ msg: @autoclosure () -> String) {
        Logger.write(.exactSequence, msg)
    }
    
    internal struct Arrow {
        var map: Map?
        var isZero: Bool
        
        init(_ map: Map?, isZero: Bool = false) {
            self.map = map
            self.isZero = isZero
        }
        
        static var identity: Arrow {
            return Arrow(Map.identity)
        }
        
        static var zero: Arrow {
            return Arrow(Map.zero, isZero: true)
        }
    }
    
    internal struct Arrows {
        internal var arrows: [Arrow]
        internal init (_ maps: [Map?]) {
            self.arrows = maps.map{ Arrow($0) }
        }
        
        public subscript(i: Int) -> Arrow {
            get {
                return (0 ..< arrows.count).contains(i) ? arrows[i] : Arrow.zero
            } set {
                if (0 ..< arrows.count).contains(i) {
                    arrows[i] = newValue
                }
            }
        }
    }
}
