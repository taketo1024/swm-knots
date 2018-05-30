//
//  GradedChainComplex.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/21.
//

import Foundation
import SwiftyMath

// TODO substitute for old ChainComplex.

public typealias ChainComplex<A: BasisElementType, R: EuclideanRing> = MChainComplex<_1, A, R>
public typealias ChainComplex2<A: BasisElementType, R: EuclideanRing> = MChainComplex<_2, A, R>

public struct MChainComplex<Dim: _Int, A: BasisElementType, R: EuclideanRing>: CustomStringConvertible {
    public typealias Base = ModuleGrid<Dim, A, R>
    public typealias Differential = MChainMap<Dim, A, A, R>
    public var base: Base
    
    public let d: Differential
    internal let dMatrices: [IntList : Cache<Matrix<R>>]
    
    public init(base: ModuleGrid<Dim, A, R>, differential d: Differential) {
        assert(base.defaultObject == nil || base.defaultObject == .some(.zeroModule))
        
        self.base = base
        self.d = d
        
        let degs = base.mDegrees.flatMap{ I in [I, I - d.mDegree] }.unique()
        self.dMatrices = Dictionary(pairs: degs.map{ I in (I, .empty) })
    }
    
    public subscript(I: IntList) -> Base.Object? {
        get {
            return base[I]
        } set {
            base[I] = newValue
        }
    }
    
    public var name: String {
        return base.name
    }
    
    public func shifted(_ I: IntList) -> MChainComplex<Dim, A, R> {
        return MChainComplex(base: base.shifted(I), differential: d.shifted(I))
    }
    
    internal func dMatrix(_ I: IntList) -> Matrix<R>? {
        if let c = dMatrices[I], let A = c.value {
            return A // cached.
        }

        let A = d.matrix(from: self, to: self, at: I)
        dMatrices[I]?.value = A
        return A
    }
    
    internal func kernel(_ I: IntList) -> Matrix<R>? {
        guard let from = base[I], from.isFree,
            let to = base[I + d.mDegree], to.isFree,
            let A = dMatrix(I) else {
                return nil // indeterminable.
        }
        
        let E = A.elimination(form: .Diagonal)
        return E.kernelMatrix
    }
    
    internal func kernelTransition(_ I: IntList) -> Matrix<R>? {
        guard let from = base[I], from.isFree,
            let to = base[I + d.mDegree], to.isFree,
            let A = dMatrix(I) else {
                return nil // indeterminable.
        }
        
        let E = A.elimination(form: .Diagonal)
        return E.kernelTransitionMatrix
    }
    
    internal func image(_ I: IntList) -> Matrix<R>? {
        guard let from = base[I], from.isFree,
            let to = base[I + d.mDegree], to.isFree,
            let A = dMatrix(I) else {
                return nil // indeterminable.
        }
        
        let E = A.elimination(form: .Diagonal)
        return E.imageMatrix
    }
    
    internal func homology(_ I: IntList) -> SimpleModuleStructure<A, R>? {
        guard let basis = base[I]?.generators,
              let Z = kernel(I),
              let T = kernelTransition(I),
              let B = image(I - d.mDegree)
            else {
            return nil // indeterminable.
        }
        
        return SimpleModuleStructure(
            basis: basis,
            generatingMatrix: Z,
            transitionMatrix: T,
            relationMatrix: T * B
        )
    }
    
    public func homology(name: String? = nil) -> ModuleGrid<Dim, A, R> {
        let list = base.mDegrees
            .map{ I in (I, homology(I)) }
            .exclude{ base.defaultObject == .zeroModule && ($0.1?.isTrivial ?? false) }
        
        return ModuleGrid(
            name: name ?? "H(\(base.name))",
            default: base.defaultObject,
            list: list
        )
    }
    
    public var isExact: Bool {
        return homology().isTrivial
    }
    
    // MEMO works only when each generator is a single basis-element.
    
    public func dual(name: String? = nil) -> MChainComplex<Dim, Dual<A>, R> {
        typealias D = MChainComplex<Dim, Dual<A>, R>
        
        let dName = name ?? "\(base.name)^*"
        let dDef = (base.defaultObject == .zeroModule) ? D.Base.Object.zeroModule : nil
        let dList: [(IntList, [Dual<A>]?)] = base.mDegrees.map { I -> (IntList, [Dual<A>]?) in
            guard let o = self[I] else {
                return (I, nil)
            }
            guard o.isFree, o.generators.forAll({ $0.basis.count == 1 }) else {
                fatalError("inavailable")
            }
            return (I, o.generators.map{ $0.basis.first!.dual })
        }
        
        let dBase = D.Base(name: dName, default: dDef, list: dList)
        let dDiff = d.dual(from: self, to: self)
        
        return D(base: dBase, differential: dDiff)
    }
    
    public func assertChainComplex(debug: Bool = false) {
        func print(_ msg: @autoclosure () -> String) {
            Swift.print(msg())
        }
        
        for I0 in base.mDegrees {
            let I1 = I0 + d.mDegree
            let I2 = I1 + d.mDegree
            
            guard let s0 = self[I0],
                  let s1 = self[I1],
                  let s2 = self[I2] else {
                    print("\(I0): undeterminable.")
                    continue
            }
            
            print("\(I0): \(s0) -> \(s1) -> \(s2)")
            
            for x in s0.generators {
                let y = d[I0].applied(to: x)
                let z = d[I1].applied(to: y)
                print("\t\(x) ->\t\(y) ->\t\(z)")
                
                assert(s2.elementIsZero(z))
            }
        }
    }
    
    public func describe(_ I: IntList) {
        base.describe(I)
    }
    
    public func describeMap(_ I: IntList) {
        print("\(I) \(self[I]?.description ?? "?") -> \(self[I + d.mDegree]?.description ?? "?")")
        if let A = dMatrix(I) {
            print("\n", A.detailDescription)
        }
    }
    
    public var description: String {
        return base.description
    }
}

public extension MChainComplex where Dim == _1 {
    public subscript(i: Int) -> Base.Object? {
        get {
            return base[i]
        } set {
            base[i] = newValue
        }
    }
    
    public var bottomDegree: Int {
        return base.bottomDegree
    }
    
    public var topDegree: Int {
        return base.topDegree
    }
    
    public func shifted(_ i: Int) -> ChainComplex<A, R> {
        return shifted(IntList(i))
    }
    
    public func homology(_ i: Int) -> SimpleModuleStructure<A, R>? {
        return homology(IntList(i))
    }
    
    public func describe(_ i: Int) {
        describe(IntList(i))
    }
    
    public func describeMap(_ i: Int) {
        describeMap(IntList(i))
    }
}

public extension MChainComplex where Dim == _2 {
    public subscript(i: Int, j: Int) -> Base.Object? {
        get {
            return base[i, j]
        } set {
            base[i, j] = newValue
        }
    }
    
    public func shifted(_ i: Int, _ j: Int) -> ChainComplex2<A, R> {
        return shifted(IntList(i, j))
    }
    
    public func homology(_ i: Int, _ j: Int) -> SimpleModuleStructure<A, R>? {
        return homology(IntList(i, j))
    }
    
    public func describe(_ i: Int, _ j: Int) {
        describe(IntList(i, j))
    }
    
    public func describeMap(_ i: Int, _ j: Int) {
        describeMap(IntList(i, j))
    }
    
    public func printTable() {
        base.printTable()
    }
}
