//
//  ChainComplexSES.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/25.
//

import Foundation
import SwiftyMath

public typealias ChainComplexSES<A: BasisElementType, B: BasisElementType, C: BasisElementType, R: EuclideanRing> = MChainComplexSES<_1, A, B, C, R>
public typealias ChainComplex2SES<A: BasisElementType, B: BasisElementType, C: BasisElementType, R: EuclideanRing> = MChainComplexSES<_2, A, B, C, R>

public struct MChainComplexSES<Dim: _Int, A: BasisElementType, B: BasisElementType, C: BasisElementType, R: EuclideanRing> {
    public let C0: MChainComplex<Dim, A, R>
    public let C1: MChainComplex<Dim, B, R>
    public let C2: MChainComplex<Dim, C, R>
    
    public let f0: MChainMap<Dim, A, B, R>
    public let f1: MChainMap<Dim, B, C, R>
    public let  d: MChainMap<Dim, C, A, R> // TODO compute from construction
    
    public init(_ C0: MChainComplex<Dim, A, R>, _ f0: MChainMap<Dim, A, B, R>,
                _ C1: MChainComplex<Dim, B, R>, _ f1: MChainMap<Dim, B, C, R>,
                _ C2: MChainComplex<Dim, C, R>, _  d: MChainMap<Dim, C, A, R>) {
        
        self.C0 = C0
        self.C1 = C1
        self.C2 = C2
        
        self.f0 = f0
        self.f1 = f1
        self.d  = d
    }
    
    public var chainComplexes: (MChainComplex<Dim, A, R>, MChainComplex<Dim, B, R>, MChainComplex<Dim, C, R>) {
        return (C0, C1, C2)
    }
    
    public var chainMaps: (MChainMap<Dim, A, B, R>, MChainMap<Dim, B, C, R>) {
        return (f0, f1)
    }
    
    //              f0        f1
    //   0 --> C0  --->  C1  ---> C2  --> 0  (exact)
    //
    //
    // ==> Hom(-, R)
    //
    //              f0*       f1*
    //   0 <-- C0* <---  C1* <--- C2* <-- 0  (exact)
    
    public var dual: MChainComplexSES<Dim, Dual<C>, Dual<B>, Dual<A>, R> {
        let (D0, D1, D2)  = (C0.dual(), C1.dual(), C2.dual())
        
        let g0 = f0.dual(from: C0, to: C1)
        let g1 = f1.dual(from: C1, to: C2)
        let dd =  d.dual(from: C2, to: C0)
        
        return MChainComplexSES<Dim, Dual<C>, Dual<B>, Dual<A>, R>(D2, g1, D1, g0, D0, dd)
    }
}
