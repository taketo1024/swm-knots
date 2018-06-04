//
//  ChainShortExactSequence.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/25.
//

import Foundation
import SwiftyMath

public typealias  ChainShortExactSequence<A: BasisElementType, B: BasisElementType, C: BasisElementType, R: EuclideanRing> = ChainShortExactSequenceN<_1, A, B, C, R>
public typealias ChainShortExactSequence2<A: BasisElementType, B: BasisElementType, C: BasisElementType, R: EuclideanRing> = ChainShortExactSequenceN<_2, A, B, C, R>

public struct ChainShortExactSequenceN<n: _Int, A: BasisElementType, B: BasisElementType, C: BasisElementType, R: EuclideanRing> {
    public let C0: ChainComplexN<n, A, R>
    public let C1: ChainComplexN<n, B, R>
    public let C2: ChainComplexN<n, C, R>
    
    public let f0: ChainMapN<n, A, B, R>
    public let f1: ChainMapN<n, B, C, R>
    public let  d: ChainMapN<n, C, A, R> // TODO compute from construction
    
    public init(_ C0: ChainComplexN<n, A, R>, _ f0: ChainMapN<n, A, B, R>,
                _ C1: ChainComplexN<n, B, R>, _ f1: ChainMapN<n, B, C, R>,
                _ C2: ChainComplexN<n, C, R>, _  d: ChainMapN<n, C, A, R>) {
        
        self.C0 = C0
        self.C1 = C1
        self.C2 = C2
        
        self.f0 = f0
        self.f1 = f1
        self.d  = d
    }
    
    public var chainComplexes: (ChainComplexN<n, A, R>, ChainComplexN<n, B, R>, ChainComplexN<n, C, R>) {
        return (C0, C1, C2)
    }
    
    public var chainMaps: (ChainMapN<n, A, B, R>, ChainMapN<n, B, C, R>) {
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
    
    public var dual: ChainShortExactSequenceN<n, Dual<C>, Dual<B>, Dual<A>, R> {
        let (D0, D1, D2)  = (C0.dual(), C1.dual(), C2.dual())
        
        let g0 = f0.dual(from: C0, to: C1)
        let g1 = f1.dual(from: C1, to: C2)
        let dd =  d.dual(from: C2, to: C0)
        
        return ChainShortExactSequenceN<n, Dual<C>, Dual<B>, Dual<A>, R>(D2, g1, D1, g0, D0, dd)
    }
}
