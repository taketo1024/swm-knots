//
//  ChainMap.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/08/01.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation
import SwiftyMath

public typealias   ChainMap<A: BasisElementType, B: BasisElementType, R: Ring> = _ChainMap<Descending, A, B, R>
public typealias CochainMap<A: BasisElementType, B: BasisElementType, R: Ring> = _ChainMap<Ascending,  A, B, R>

// TODO conform Module<R>
public struct _ChainMap<T: ChainType, A: BasisElementType, B: BasisElementType, R: Ring>: ModuleHomType {
    public typealias CoeffRing = R
    public typealias Domain   = FreeModule<A, R>
    public typealias Codomain = FreeModule<B, R>
    
    public var degree: Int
    internal let f: FreeModuleHom<A, B, R>
    
    public init(_ f: @escaping (Domain) -> Codomain) { // required
        self.init(degree: 0, FreeModuleHom(f))
    }
    
    public init(degree: Int = 0, _ f: @escaping (A) -> Codomain) {
        self.init(degree: degree, FreeModuleHom(f))
    }
    
    public init(degree: Int, _ f: @escaping (Domain) -> Codomain) {
        self.init(degree: degree, FreeModuleHom(f))
    }
    
    public init(degree: Int = 0, _ f: FreeModuleHom<A, B, R>) {
        self.degree = degree
        self.f = f
    }
    
    public func applied(to a: A) -> FreeModule<B, R> {
        return f.applied(to: a)
    }
    
    public func applied(to x: FreeModule<A, R>) -> FreeModule<B, R> {
        return f.applied(to: x)
    }
    
    public static func ∘<C>(g: _ChainMap<T, B, C, R>, f: _ChainMap<T, A, B, R>) -> _ChainMap<T, A, C, R> {
        return _ChainMap<T, A, C, R>(degree: f.degree + g.degree, g.f ∘ f.f)
    }
    
    public func asAbstract(from: _ChainComplex<T, A, R>, to: _ChainComplex<T, B, R>) -> _ChainMap<T, AbstractBasisElement, AbstractBasisElement, R> {
        
        //      self
        //   A  ----> B
        //   ^        |
        // f1|        |f2
        //   |        v
        //   X  ====> X
        //
        
        typealias X = AbstractBasisElement
        
        let p1 = from.abstractBasisDict().inverse!.asFunc()
        let p2 = to.abstractBasisDict().asFunc()
        
        let f1 = _ChainMap<T, X, A, R> { (a: X) in FreeModule(p1(a)) }
        let f2 = _ChainMap<T, B, X, R> { (b: B) in FreeModule(p2(b)) }
        let f = f2 ∘ self ∘ f1

        return _ChainMap<T, X, X, R> (degree: degree) {
            (x: X) in f.applied(to: x)
        }
    }
    
    public func assertChainMap(from: _ChainComplex<T, A, R>, to: _ChainComplex<T, B, R>, debug: Bool = false) {
        (min(from.offset, to.offset) ... max(from.topDegree, to.topDegree)).forEach { i in
            
            //          f
            //   C[i] -----> C'[i]
            //     |          |
            //   d1|          |d2
            //     v          v
            //  C[i-1] ---> C'[i-1]
            //          f
            
            let basis = from.chainBasis(i)
            if debug {
                print("C\(i) : \(basis)\n")
            }
            
            let d1 = from.boundaryMap(i)
            
            for a in basis {
                let x1 = f.applied(to: a)
                let d2 = to.boundaryMap(i + degree)
                let x2 = d2.applied(to: x1)
                
                let y1 = d1.applied(to: a)
                let y2 = f.applied(to: y1)
                
                if debug {
                    print("\td2 ∘ f1: \(a) ->\t\(x1) ->\t\(x2)")
                    print("\tf2 ∘ d1: \(a) ->\t\(y1) ->\t\(y2)")
                    print()
                }
                
                assert(x2 == y2)
            }
        }
    }
}

public extension ChainMap where T == Descending {
    
    // f: C1 -> C2  ==>  f^*: Hom(C1, R) <- Hom(C1, R) , pullback
    //                        g∘f        <- g

    public func dual(domain C: ChainComplex<A, R>) -> CochainMap<Dual<B>, Dual<A>, R> {
        return CochainMap (degree: -degree) { (d: Dual<B>) -> FreeModule<Dual<A>, R> in
            let i = d.degree - self.degree
            let values = C.chainBasis(i).compactMap { s -> (Dual<A>, R)? in
                let a = self.applied(to: s)[d.base]
                return (a != .zero) ? (Dual(s), a) : nil
            }
            return FreeModule(values)
        }
    }
}
