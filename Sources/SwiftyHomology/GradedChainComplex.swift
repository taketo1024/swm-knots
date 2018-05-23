//
//  GradedChainComplex.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/21.
//

import Foundation
import SwiftyMath

// TODO substitute for old ChainComplex.

public typealias   GradedChainComplex<A: BasisElementType, R: EuclideanRing> = _GradedChainComplex<_1, A, R>
public typealias BigradedChainComplex<A: BasisElementType, R: EuclideanRing> = _GradedChainComplex<_2, A, R>

public struct _GradedChainComplex<Dim: _Int, A: BasisElementType, R: EuclideanRing> {
    public typealias Base = _GradedModuleStructure<Dim, A, R>
    public var base: Base
    
    internal let _degree: IntList
    internal let map: (IntList, A) -> FreeModule<A, R>
    internal let matrices: [IntList : Cache<Matrix<R>>]
    
    internal init(base: _GradedModuleStructure<Dim, A, R>, degree: IntList, map: @escaping (IntList, A) -> FreeModule<A, R>) {
        self.base = base
        self._degree = degree
        self.map = map
        
        let degs = base._nonZeroDegrees.flatMap{ I in [I, I - degree] }.unique()
        self.matrices = Dictionary(pairs: degs.map{ I in (I, .empty) })
    }
    
    internal subscript(I: IntList) -> Base.Object? {
        get {
            return base[I]
        } set {
            base[I] = newValue
        }
    }
    
    internal func matrix(_ I: IntList) -> Matrix<R>? {
        guard let from = base[I], let to = base[I + _degree] else {
            return nil // indeterminable.
        }
        
        if from.isTrivial && to.isTrivial {
            return .zero
        }
        
        if let c = matrices[I], let A = c.value {
            return A // cached.
        }
        
        let grid = from.generators.flatMap { x -> [R] in
            let y = x.elements.sum{ (a, r) in r * map(I, a)}
            return to.factorize(y)
        }
        
        let A = Matrix(rows: from.generators.count, cols: to.generators.count, grid: grid).transposed
        matrices[I]!.value = A
        return A
    }
    
    internal func kernel(_ I: IntList) -> Matrix<R>? {
        guard let from = base[I], from.isFree,
            let to = base[I + _degree], to.isFree,
            let A = matrix(I) else {
                return nil // indeterminable.
        }
        
        let E = A.elimination(form: .Diagonal)
        return E.kernelMatrix
    }
    
    internal func kernelTransition(_ I: IntList) -> Matrix<R>? {
        guard let from = base[I], from.isFree,
            let to = base[I + _degree], to.isFree,
            let A = matrix(I) else {
                return nil // indeterminable.
        }
        
        let E = A.elimination(form: .Diagonal)
        return E.kernelTransitionMatrix
    }
    
    internal func image(_ I: IntList) -> Matrix<R>? {
        guard let from = base[I], from.isFree,
            let to = base[I + _degree], to.isFree,
            let A = matrix(I) else {
                return nil // indeterminable.
        }
        
        let E = A.elimination(form: .Diagonal)
        return E.imageMatrix
    }
    
    internal func homology(_ I: IntList) -> SimpleModuleStructure<A, R>? {
        guard let basis = base[I]?.generators,
              let Z = kernel(I),
              let T = kernelTransition(I),
              let B = image(I - _degree)
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
    
    public func homology(name: String? = nil) -> _GradedModuleStructure<Dim, A, R> {
        return _GradedModuleStructure(
            name: name ?? "H(\(base.name))",
            list: base._nonZeroDegrees.map{ I in (I, homology(I)) }
        )
    }
    
    // MEMO works only when each generator is a single basis-element.
    
    public func dual(name: String? = nil) -> _GradedChainComplex<Dim, Dual<A>, R> {
        let dName = name ?? "\(base.name)^*"
        let dList: [(IntList, [Dual<A>]?)] = base._nonZeroDegrees.map { I -> (IntList, [Dual<A>]?) in
            guard let o = self[I] else {
                return (I, nil)
            }
            guard o.isFree, o.generators.forAll({ $0.basis.count == 1 }) else {
                fatalError("inavailable")
            }
            return (I, o.generators.map{ $0.basis.first!.dual })
        }
        
        let dBase = _GradedModuleStructure<Dim, Dual<A>, R>(name: dName, list: dList)
        return dBase.asChainComplex(degree: -_degree) { (I0, x) in
            let I1 = I0 - self._degree
            guard let current = dBase[I0],
                let target = dBase[I1],
                let matrix = self.matrix(I1)?.transposed else {
                    return .zero
            }
            
            guard let j = current.generators.index(where: { $0 == FreeModule(x) }) else {
                fatalError()
            }
            
            return matrix.nonZeroComponents(ofCol: j).sum { (c: MatrixComponent<R>) in
                let (i, r) = (c.row, c.value)
                return r * target.generator(i)
            }
        }
    }
    
    internal func describe(_ I: IntList) {
        base.describe(I)
    }
    
    internal func describeMap(_ I: IntList) {
        print("\(I) \(self[I]?.description ?? "?") -> \(self[I + _degree]?.description ?? "?")")
        if let A = matrix(I) {
            print("\n", A.detailDescription)
        }
    }
}

public extension _GradedChainComplex where Dim == _1 {
    public var degree: Int {
        return _degree[0]
    }
    
    public func matrix(_ i: Int) -> Matrix<R>? {
        return matrix(IntList(i))
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

public extension _GradedChainComplex where Dim == _2 {
    public var degree: (Int, Int) {
        return (_degree[0], _degree[1])
    }
    
    public func matrix(_ i: Int, _ j: Int) -> Matrix<R>? {
        return matrix(IntList(i, j))
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
}
