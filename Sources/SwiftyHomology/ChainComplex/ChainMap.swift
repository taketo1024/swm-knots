//
//  GradedModuleMap.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/05/23.
//

import Foundation
import SwiftyMath

public typealias  ChainMap<A: BasisElementType, B: BasisElementType, R: EuclideanRing> = ChainMapN<_1, A, B, R>
public typealias ChainMap2<A: BasisElementType, B: BasisElementType, R: EuclideanRing> = ChainMapN<_2, A, B, R>

public struct ChainMapN<n: _Int, A: BasisElementType, B: BasisElementType, R: EuclideanRing> {
    public var mDegree: IntList
    internal let f: (IntList) -> FreeModuleHom<A, B, R>
    
    public init(mDegree: IntList, _ f: @escaping (IntList) -> FreeModuleHom<A, B, R>) {
        self.mDegree = mDegree
        self.f = f
    }
    
    public static func uniform(mDegree: IntList, _ f: FreeModuleHom<A, B, R>) -> ChainMapN<n, A, B, R> {
        return ChainMapN(mDegree: mDegree) { _ in f }
    }
    
    public static func uniform(mDegree: IntList, _ f: @escaping (A) -> FreeModule<B, R>) -> ChainMapN<n, A, B, R> {
        return .uniform(mDegree: mDegree, FreeModuleHom(f))
    }
    
    public static func uniform(mDegree: IntList, _ f: @escaping (FreeModule<A, R>) -> FreeModule<B, R>) -> ChainMapN<n, A, B, R> {
        return .uniform(mDegree: mDegree, FreeModuleHom(f))
    }
    
    public subscript(_ I: IntList) -> FreeModuleHom<A, B, R> {
        return f(I)
    }
    
    public func shifted(_ I0: IntList) -> ChainMapN<n, A, B, R> {
        return ChainMapN(mDegree: mDegree) { I in self[I - I0] }
    }

    public func matrix(from: ChainComplexN<n, A, R>, to: ChainComplexN<n, B, R>, at I: IntList) -> Matrix<R>? {
        guard let s0 = from[I], let s1 = to[I + mDegree] else {
            return nil
        }
        
        if s0.isZero || s1.isZero {
            return .zero(rows: s1.generators.count, cols: s0.generators.count) // trivially zero
        }
        
        let map = self[I]
        
        if  s0.isFree, s0.generators.forAll({ $0.isSingle }),
            s1.isFree, s1.generators.forAll({ $0.isSingle }) {
            
            let (from, to) = (s0.generators.map{ $0.basis[0] }, s1.generators.map{ $0.basis[0] })
            let toIndexer = to.indexer()
            
            let components = from.enumerated().flatMap{ (j, x) -> [MatrixComponent<R>] in
                map.applied(to: x).elements.map { (y, a) -> MatrixComponent<R> in
                    let i = toIndexer(y)
                    return MatrixComponent(i, j, a)
                }
            }
            
            return Matrix(rows: to.count, cols: from.count, components: components)
        }
        
        let grid = s0.generators.flatMap { x -> [R] in
            let y = map.applied(to: x)
            return s1.factorize(y)
        }
        
        return Matrix(rows: s0.generators.count, cols: s1.generators.count, grid: grid).transposed
    }

    public func dual(from: ChainComplexN<n, A, R>, to: ChainComplexN<n, B, R>) -> ChainMapN<n, Dual<B>, Dual<A>, R> {
        typealias F = ChainMapN<n, Dual<B>, Dual<A>, R>
        return F(mDegree: -mDegree) { I1 in
            FreeModuleHom<Dual<B>, Dual<A>, R>{ (b: Dual<B>) in
                let I0 = I1 - self.mDegree
                guard let s0 = from[I0],
                    let s1  =  to[I1],
                    let matrix = self.matrix(from: from, to: to, at: I0) else {
                        return .zero
                }
                
                guard s0.isFree, s0.generators.forAll({ $0.isSingle }),
                    s1.isFree, s1.generators.forAll({ $0.isSingle }) else {
                        fatalError("inavailable")
                }
                
                // MEMO: the matrix of the dual-map w.r.t the dual-basis is the transpose of the original.
                
                guard let i = s1.generators.index(where: { $0.unwrap() == b.base }) else {
                    fatalError()
                }
                
                return matrix.nonZeroComponents(ofRow: i).sum { (c: MatrixComponent<R>) in
                    let (j, r) = (c.col, c.value)
                    return r * s0.generator(j).mapBasis{ $0.dual }
                }
            }
        }
    }
    
    public func assertChainMap(from C0: ChainComplexN<n, A, R>, to C1: ChainComplexN<n, B, R>, debug: Bool = false) {
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
                let y0 = d0[I0].applied(to: x)
                let z0 =  f[I1].applied(to: y0)
                print("\t\(x) ->\t\(y0) ->\t\(z0)")
                
                let y1 =  f[I0].applied(to: x)
                let z1 = d1[I2].applied(to: y1)
                print("\t\(x) ->\t\(y1) ->\t\(z1)")
                print("")
                
                assert(s3.elementsAreEqual(z0, z1))
            }
        }
    }
}

public extension ChainMapN where n == _1 {
    public init(degree: Int, _ f: @escaping (Int) -> FreeModuleHom<A, B, R>) {
        self.init(mDegree: IntList(degree)) { I in f(I[0]) }
    }
    
    public static func uniform(degree: Int, _ f: FreeModuleHom<A, B, R>) -> ChainMap<A, B, R> {
        return ChainMap(degree: degree) { _ in f }
    }
    
    public static func uniform(degree: Int, _ f: @escaping (A) -> FreeModule<B, R>) -> ChainMap<A, B, R> {
        return .uniform(degree: degree, FreeModuleHom(f))
    }
    
    public static func uniform(degree: Int, _ f: @escaping (FreeModule<A, R>) -> FreeModule<B, R>) -> ChainMap<A, B, R> {
        return .uniform(degree: degree, FreeModuleHom(f))
    }
    
    public subscript(_ i: Int) -> FreeModuleHom<A, B, R> {
        return self[IntList(i)]
    }
    
    public var degree: Int {
        return mDegree[0]
    }
    
    public func matrix(from: ChainComplex<A, R>, to: ChainComplex<B, R>, at i: Int) -> Matrix<R>? {
        return matrix(from: from, to: to, at: IntList(i))
    }
}

public extension ChainMapN where n == _2 {
    public init(bidegree: (Int, Int), _ f: @escaping (Int, Int) -> FreeModuleHom<A, B, R>) {
        let (i, j) = bidegree
        self.init(mDegree: IntList(i, j)) { I in f(I[0], I[1]) }
    }
    
    public static func uniform(bidegree: (Int, Int), _ f: FreeModuleHom<A, B, R>) -> ChainMap2<A, B, R> {
        return ChainMap2(bidegree: bidegree) { _, _ in f }
    }
    
    public static func uniform(bidegree: (Int, Int), _ f: @escaping (A) -> FreeModule<B, R>) -> ChainMap2<A, B, R> {
        return .uniform(bidegree: bidegree, FreeModuleHom(f))
    }
    
    public static func uniform(bidegree: (Int, Int), _ f: @escaping (FreeModule<A, R>) -> FreeModule<B, R>) -> ChainMap2<A, B, R> {
        return .uniform(bidegree: bidegree, FreeModuleHom(f))
    }
    
    public subscript(_ i: Int, _ j: Int) -> FreeModuleHom<A, B, R> {
        return self[IntList(i, j)]
    }
    
    public var bidegree: (Int, Int) {
        return (mDegree[0], mDegree[1])
    }
}

public extension ChainMapN where R == 𝐙 {
    public var tensor2: ChainMapN<n, A, B, 𝐙₂> {
        return ChainMapN<n, A, B, 𝐙₂>(mDegree: mDegree) { I -> FreeModuleHom<A, B, 𝐙₂> in
            FreeModuleHom{ (a: A) -> FreeModule<B, 𝐙₂> in
                return self[I].applied(to: a).mapValues{ r in 𝐙₂(r) }
            }
        }
    }
}
