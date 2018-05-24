//
//  GradedModuleMap.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/05/23.
//

import Foundation
import SwiftyMath

public typealias ChainMap<A: BasisElementType, B: BasisElementType, R: EuclideanRing> = MChainMap<_1, A, B, R>
public typealias BigradedChainMap<A: BasisElementType, B: BasisElementType, R: EuclideanRing> = MChainMap<_2, A, B, R>

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
        
        for I0 in C0.base.nonZeroMultiDegrees {
            let (I1, I2, I3) = (I0 + d0.mDegree, I0 + f.mDegree, I0 + d0.mDegree + f.mDegree)
            
            guard let D0 = C0.dMatrix(I0),
                  let D1 = C1.dMatrix(I2),
                  let F0 = f.matrix(from: C0, to: C1, at: I0),
                  let F1 = f.matrix(from: C0, to: C1, at: I1) else {
                    print("\(I0): undeterminable.")
                    continue
            }
            
            if debug {
                let (s0, s1, s2, s3) = (C0[I0]!, C0[I1]!, C1[I2]!, C1[I3]!)
                print("\(I0): \(s0) -> \(s1) -> \(s3)")
                
                for x in s0.generators {
                    let y = d0[I0](x)
                    let z = f[I1](y)
                    print("\t\(x) ->\t\(y) ->\t\(z)")
                }
                
                print("\(I0): \(s0) -> \(s2) -> \(s3)")
                
                for x in s0.generators {
                    let y = f[I0](x)
                    let z = d1[I2](y)
                    print("\t\(x) ->\t\(y) ->\t\(z)")
                }
                
                print("")
            }
            
            assert(F1 * D0 == D1 * F0)
        }
    }
}

public extension MChainMap where Dim == _1 {
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

public extension MChainMap where Dim == _2 {
    public init(degree: (Int, Int), func f: @escaping (Int, Int, A) -> FreeModule<B, R>) {
        self.init(degree: IntList(degree.0, degree.1), func: {(I, a) in f(I[0], I[1], a)})
    }
}
