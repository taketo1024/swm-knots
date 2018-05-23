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
    
    internal func _matrix(_ I: IntList) -> Matrix<R>? {
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
    
    internal func _kernel(_ I: IntList) -> Matrix<R>? {
        guard let from = base[I], from.isFree,
            let to = base[I + _degree], to.isFree,
            let A = _matrix(I) else {
                return nil // indeterminable.
        }
        
        let E = A.elimination(form: .Diagonal)
        return E.kernelMatrix
    }
    
    internal func _kernelTransition(_ I: IntList) -> Matrix<R>? {
        guard let from = base[I], from.isFree,
            let to = base[I + _degree], to.isFree,
            let A = _matrix(I) else {
                return nil // indeterminable.
        }
        
        let E = A.elimination(form: .Diagonal)
        return E.kernelTransitionMatrix
    }
    
    internal func _image(_ I: IntList) -> Matrix<R>? {
        guard let from = base[I], from.isFree,
            let to = base[I + _degree], to.isFree,
            let A = _matrix(I) else {
                return nil // indeterminable.
        }
        
        let E = A.elimination(form: .Diagonal)
        return E.imageMatrix
    }
    
    internal func _homology(_ I: IntList) -> SimpleModuleStructure<A, R>? {
        guard let basis = base[I]?.generators,
              let Z = _kernel(I),
              let T = _kernelTransition(I),
              let B = _image(I - _degree)
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
            list: base._nonZeroDegrees.map{ I in (I, _homology(I)) }
        )
    }
    
    internal func _describe(_ I: IntList) {
        base._describe(I)
    }
    
    internal func _describeMap(_ I: IntList) {
        print("\(I) \(self[I]?.description ?? "?") -> \(self[I + _degree]?.description ?? "?")")
        if let A = _matrix(I) {
            print("\n", A.detailDescription)
        }
    }
}

public extension _GradedChainComplex where Dim == _1 {
    public var degree: Int {
        return _degree[0]
    }
    
    public func matrix(_ i: Int) -> Matrix<R>? {
        return _matrix(IntList(i))
    }
    
    public func homology(_ i: Int) -> SimpleModuleStructure<A, R>? {
        return _homology(IntList(i))
    }
    
    public func describe(_ i: Int) {
        _describe(IntList(i))
    }
    
    public func describeMap(_ i: Int) {
        _describeMap(IntList(i))
    }
}

public extension _GradedChainComplex where Dim == _2 {
    public var degree: (Int, Int) {
        return (_degree[0], _degree[1])
    }
    
    public func matrix(_ i: Int, _ j: Int) -> Matrix<R>? {
        return _matrix(IntList(i, j))
    }
    
    public func homology(_ i: Int, _ j: Int) -> SimpleModuleStructure<A, R>? {
        return _homology(IntList(i, j))
    }
    
    public func describe(_ i: Int, _ j: Int) {
        _describe(IntList(i, j))
    }
    
    public func describeMap(_ i: Int, _ j: Int) {
        _describeMap(IntList(i, j))
    }
}
