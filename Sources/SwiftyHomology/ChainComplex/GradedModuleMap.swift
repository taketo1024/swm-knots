//
//  GradedModuleMap.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/05/23.
//

import Foundation
import SwiftyMath

public typealias GradedModuleHom<A: BasisElementType, B: BasisElementType, R: EuclideanRing> = MultigradedModuleHom<_1, A, B, R>
public typealias BigradedModuleHom<A: BasisElementType, B: BasisElementType, R: EuclideanRing> = MultigradedModuleHom<_2, A, B, R>

public struct MultigradedModuleHom<Dim: _Int, A: BasisElementType, B: BasisElementType, R: EuclideanRing> {
    public var mDegree: IntList
    internal let f: (IntList, A) -> FreeModule<B, R>
    
    public init(degree: IntList, func f: @escaping (IntList, A) -> FreeModule<B, R>) {
        self.mDegree = degree
        self.f = f
    }
    
    public subscript(_ I: IntList) -> (FreeModule<A, R>) -> FreeModule<B, R> {
        return { x in x.elements.sum{ (a, r) in r * self.f(I, a) } }
    }
    
    public func matrix(from: MultigradedModuleStructure<Dim, A, R>, to: MultigradedModuleStructure<Dim, B, R>, at I: IntList) -> Matrix<R>? {
        guard let s0 = from[I], let s1 = to[I + mDegree] else {
            return nil
        }
        
        if s0.isTrivial || s1.isTrivial {
            return .zero(rows: s1.generators.count, cols: s0.generators.count) // trivially zero
        }
        
        let grid = s0.generators.flatMap { x -> [R] in
            let y = self[I](x)
            return s1.factorize(y)
        }
        
        return Matrix(rows: s0.generators.count, cols: s1.generators.count, grid: grid).transposed
    }

    public func matrix(from: MultigradedChainComplex<Dim, A, R>, to: MultigradedChainComplex<Dim, B, R>, at I: IntList) -> Matrix<R>? {
        return matrix(from: from.base, to: to.base, at: I)
    }
}

public extension MultigradedModuleHom where Dim == _1 {
    public init(degree: Int, func f: @escaping (Int, A) -> FreeModule<B, R>) {
        self.init(degree: IntList(degree), func: {(I, a) in f(I[0], a)})
    }
    
    public var degree: Int {
        return mDegree[0]
    }
    
    public func matrix(from: GradedModuleStructure<A, R>, to: GradedModuleStructure<B, R>, at i: Int) -> Matrix<R>? {
        return matrix(from: from, to: to, at: IntList(i))
    }
    
    public func matrix(from: ChainComplex<A, R>, to: ChainComplex<B, R>, at i: Int) -> Matrix<R>? {
        return matrix(from: from, to: to, at: IntList(i))
    }
}

public extension MultigradedModuleHom where Dim == _2 {
    public init(degree: (Int, Int), func f: @escaping (Int, Int, A) -> FreeModule<B, R>) {
        self.init(degree: IntList(degree.0, degree.1), func: {(I, a) in f(I[0], I[1], a)})
    }
}
