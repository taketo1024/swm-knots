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

public final class ExactSequenceSolver<R: EuclideanRing>: CustomStringConvertible {
    public typealias Object = ModuleObject<AbstractBasisElement, R>
    public typealias Map    = FreeModuleHom<AbstractBasisElement, AbstractBasisElement, R>
    
    public   var objects : Grid1<Object>
    public   var maps    : Grid1<Map>
    internal var matrices: Grid1<Matrix<R>>
    
    public init(objects: [Object?], maps: [Map?]) {
        self.objects  = Grid1(data: objects.toDictionary())
        self.maps     = Grid1(data: maps.toDictionary())
        self.matrices = Grid1.empty
    }

    public convenience init() {
        self.init(objects: [], maps: [])
    }
    
    public subscript(i: Int) -> Object? {
        get {
            return objects[i]
        } set {
            log("set \(i) = \(newValue.map{ "\($0)" } ?? "nil")")
            objects[i] = newValue
        }
    }
    
    public var length: Int {
        return objects.isEmpty ? 0 : objects.topIndex - objects.bottomIndex + 1
    }
    
    public var range: [Int] {
        return objects.isEmpty ? [] : (objects.bottomIndex ... objects.topIndex).toArray()
    }
    
    public func matrix(_ i: Int) -> Matrix<R>? {
        if let A = matrices[i] {
            return A
        }
        
        let A = _matrix(i)
        matrices[i] = A
        
        return A
    }
    
    private func _matrix(_ i: Int) -> Matrix<R>? {
        guard
            let from = self[i],
            let to   = self[i + 1],
            let map  = maps[i]
            else {
                return nil
        }
        
        let comps = from.generators.enumerated().flatMap { (j, z) -> [MatrixComponent<R>] in
            let w = map.applied(to: z)
            let vec = to.factorize(w)
            return vec.enumerated().map{ (i, a) in MatrixComponent(i, j, a) }
        }
        
        return Matrix(rows: to.generators.count, cols: from.generators.count, components: comps)
    }
    
    public func isZero(_ i: Int) -> Bool {
        return self[i]?.isZero ?? false
    }
    
    public func isNonZero(_ i: Int) -> Bool {
        return self[i].map{ !$0.isZero } ?? false
    }
    
    public func isZeroMap(_ i1: Int) -> Bool {
        if _isZeroMap(i1) {
            let i2 = i1 + 1
            if matrices[i1] == nil, let M1 = self[i1], let M2 = self[i2] {
                log("\(i1) -> \(i2): zeroMap")
                matrices[i1] = .zero(rows: M2.generators.count, cols: M1.generators.count)
            }
            return true
        } else {
            return false
        }
    }

    private func _isZeroMap(_ i1: Int) -> Bool {
        if let A = matrices[i1], A.isZero {
            return true
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
        
        let (i0, i2, i3) = (i1 - 1, i1 + 1, i1 + 2)
        
        if let M1 = self[i1], M1.isZero {
            return true
        }
        
        if let M2 = self[i2], M2.isZero {
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
    
    public func solve() {
        return range.forEach{ i in
            if objects[i] == nil {
                solve(i)
            }
        }
    }
    
    @discardableResult
    public func solve(_ i: Int) -> Object? {
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
    
    private func _solve(_ i2: Int) -> Object? {
        
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
        
        if isZeroMap(i1), isZeroMap(i2) {
            log("\(i2): trivial.")
            return Object.zeroModule
        }
        
        // Case 2.
        //
        //     0       f1        0
        // M0 ---> M1 ---> [M2] ---> M3  ==>  f1: isom
        
        if let M1 = self[i1], isZeroMap(i0), isZeroMap(i2) {
            log("\(i2): isom to \(i1).")
            maps[i1] = .identity
            return M1
        }
        
        // Case 3.
        //
        //     0         f2      0
        // M1 ---> [M2] ---> M3 ---> M4  ==>  f2: isom
        
        if let M3 = self[i3], isZeroMap(i1), isZeroMap(i3) {
            log("\(i2): isom to \(i3).")
            maps[i2] = .identity
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
        
        if  let M1 = self[i1], M1.isFree, // TODO concider non-free case
            let M3 = self[i3], M3.isFree,
            let A0 = matrix(i0),
            let A3 = matrix(i3)
        {
            let (r, k) = (M1.rank, A3.elimination().nullity)
            let generators = AbstractBasisElement.generateBasis(r + k)
            let B = A0 + Matrix<R>.zero(rows: k, cols: k)
            let M2 = Object(generators: generators, relationMatrix: B)
            
            log("\(i2): \(M2)")
            
            return M2
        }
        
        log("\(i2): unsolvable.")
        return nil
    }
    
    public func describe(_ i0: Int) {
        if let s = self[i0] {
            print("\(i0): ", terminator: "")
            s.describe()
        } else {
            print("\(i0): ?")
        }
    }
    
    public func describeMap(_ i0: Int) {
        let i1 = i0 + 1
        print("\(i0): \(objectDescription(i0)) \(arrowDescription(i0)) \(objectDescription(i1))")
        
        if let A = self.matrix(i0) {
            print(A.detailDescription, "\n")
        }
    }
    
    public func assertExactness(at i1: Int, debug: Bool = false) {
        
        //     f0        f1
        // M0 ---> [M1] ---> M2
        
        let (i0, i2) = (i1 - 1, i1 + 1)
        
        guard
            let M0 = self[i0],
            let M1 = self[i1],
            let M2 = self[i2],
            let f0 = maps[i0],
            let f1 = maps[i1]
            else {
                return
        }
        
        if M1.isZero {
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
    
    public func assertExactness(debug: Bool = false) {
        for i in range {
            assertExactness(at: i, debug: debug)
        }
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
        if objects.isEmpty {
            return "ExSeq<\(R.symbol)>: empty"
        } else {
            let (i0, i1) = (objects.bottomIndex, objects.topIndex)
            return "ExSeq<\(R.symbol)>: "
                + (i0 ..< i1).map { i in "\(objectDescription(i)) \(arrowDescription(i)) " }.joined()
                + objectDescription(i1)
        }
    }
    
    private func log(_ msg: @autoclosure () -> String) {
        Logger.write(.exactSequence, msg)
    }
}
