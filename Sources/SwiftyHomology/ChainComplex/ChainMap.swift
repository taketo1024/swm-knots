//
//  GradedModuleMap.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/05/23.
//

import Foundation
import SwiftyMath

public typealias  ChainMap<A: BasisElementType, B: BasisElementType, R: EuclideanRing> = MChainMap<_1, A, B, R>
public typealias ChainMap2<A: BasisElementType, B: BasisElementType, R: EuclideanRing> = MChainMap<_2, A, B, R>

public struct MChainMap<Dim: _Int, A: BasisElementType, B: BasisElementType, R: EuclideanRing> {
    public var mDegree: IntList
    internal let f: (IntList, A) -> FreeModule<B, R>
    
    public init(degree: IntList, func f: @escaping (IntList, A) -> FreeModule<B, R>) {
        self.mDegree = degree
        self.f = f
    }
    
    public subscript(_ I: IntList) -> (FreeModule<A, R>) -> FreeModule<B, R> {
        return { x in x.elements.sum{ (a, r) in r * self.f(I, a) } }
    }
    
    public func matrix(from: ModuleGrid<Dim, A, R>, to: ModuleGrid<Dim, B, R>, at I: IntList) -> Matrix<R>? {
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

    public func matrix(from: MChainComplex<Dim, A, R>, to: MChainComplex<Dim, B, R>, at I: IntList) -> Matrix<R>? {
        return matrix(from: from.base, to: to.base, at: I)
    }
    
    public func assertChainMap(from C0: MChainComplex<Dim, A, R>, to C1: MChainComplex<Dim, B, R>, debug: Bool = false) {
        func print(_ msg: @autoclosure () -> String) {
            Swift.print(msg())
        }
        
        //          d0
        //  C0[I0] -----> C0[I1]
        //     |           |
        //   f |           | f
        //     v           v
        //  C1[I2] -----> C1[I3]
        //          d1
        
        let (f, d0, d1) = (self, C0.d, C1.d)
        
        assert(d0.mDegree == d1.mDegree)
        
        for I0 in C0.base.mDegrees {
            let (I1, I2, I3) = (I0 + d0.mDegree, I0 + f.mDegree, I0 + d0.mDegree + f.mDegree)
            
            guard let s0 = C0[I0], let s3 = C1[I3] else {
                    print("\(I0): undeterminable.")
                    continue
            }
            
            print("\(I0): \(s0) -> \(s3)")
            
            for x in s0.generators {
                let y0 = d0[I0](x)
                let z0 = f[I1](y0)
                print("\t\(x) ->\t\(y0) ->\t\(z0)")
                
                let y1 = f[I0](x)
                let z1 = d1[I2](y1)
                print("\t\(x) ->\t\(y1) ->\t\(z1)")
                print("")
                
                assert(s3.elementsAreEqual(z0, z1))
            }
        }
    }
}

public extension MChainMap where Dim == _1 {
    public init(degree: Int, func f: @escaping (Int, A) -> FreeModule<B, R>) {
        self.init(degree: IntList(degree), func: {(I, a) in f(I[0], a)})
    }
    
    public subscript(_ i: Int) -> (FreeModule<A, R>) -> FreeModule<B, R> {
        return { x in x.elements.sum{ (a, r) in r * self.f(IntList(i), a) } }
    }
    
    public var degree: Int {
        return mDegree[0]
    }
    
    public func matrix(from: ModuleSequence<A, R>, to: ModuleSequence<B, R>, at i: Int) -> Matrix<R>? {
        return matrix(from: from, to: to, at: IntList(i))
    }
    
    public func matrix(from: ChainComplex<A, R>, to: ChainComplex<B, R>, at i: Int) -> Matrix<R>? {
        return matrix(from: from, to: to, at: IntList(i))
    }
}

public extension MChainMap where Dim == _2 {
    public init(degree: (Int, Int), func f: @escaping (Int, Int, A) -> FreeModule<B, R>) {
        self.init(degree: IntList(degree.0, degree.1), func: {(I, a) in f(I[0], I[1], a)})
    }
    
    public subscript(_ i: Int, _ j: Int) -> (FreeModule<A, R>) -> FreeModule<B, R> {
        return { x in x.elements.sum{ (a, r) in r * self.f(IntList(i, j), a) } }
    }
}
