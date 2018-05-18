//
//  File.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2018/05/16.
//

import Foundation
import SwiftyMath

public typealias   ChainComplexSES<A: BasisElementType, B: BasisElementType, C: BasisElementType, R: EuclideanRing>
    = _ChainComplexSES<Descending, A, B, C, R>
public typealias CochainComplexSES<A: BasisElementType, B: BasisElementType, C: BasisElementType, R: EuclideanRing>
    = _ChainComplexSES< Ascending, A, B, C, R>

public struct _ChainComplexSES<T: ChainType, A: BasisElementType, B: BasisElementType, C: BasisElementType, R: EuclideanRing> {
    internal typealias Ch<X: BasisElementType> = _ChainComplex<T, X, R>
    internal typealias Map<X: BasisElementType, Y: BasisElementType> = _ChainMap<T, X, Y, R>
    
    public var c0: _ChainComplex<T, A, R>
    public var c1: _ChainComplex<T, B, R>
    public var c2: _ChainComplex<T, C, R>
    
    public var f0: _ChainMap<T, A, B, R>
    public var f1: _ChainMap<T, B, C, R>
    public var  d: _ChainMap<T, C, A, R>

    // MEMO: f0, f1 are assumed to be deg-0 chain maps.
    
    public init(_ c0: _ChainComplex<T, A, R>, _ f0 : _ChainMap<T, A, B, R>,
                _ c1: _ChainComplex<T, B, R>, _ f1 : _ChainMap<T, B, C, R>,
                _ c2: _ChainComplex<T, C, R>, _ d:   _ChainMap<T, C, A, R>) {
        
        self.c0 = c0
        self.c1 = c1
        self.c2 = c2
        
        self.f0 = f0
        self.f1 = f1
        self.d = d
    }
    
    public var topDegree: Int {
        return [c0.topDegree, c1.topDegree, c2.topDegree].max()!
    }
    
    public var bottomDegree: Int {
        return [c0.offset, c1.offset, c2.offset].min()!
    }
    
    public func assertExactness(debug: Bool = false) {
        for n in (bottomDegree ... topDegree) {
            typealias M = Matrix<R>
            let (b0, b1, b2) = (c0.chainBasis(n), c1.chainBasis(n), c2.chainBasis(n))
            let (A0, A1, A2, A3) = (M.zero(rows: b0.count, cols: 0),
                                    f0.asMatrix(from: b0, to: b1),
                                    f1.asMatrix(from: b1, to: b2),
                                    M.zero(rows: 0, cols: b2.count))
            
            assertExactness(A0, A1)
            assertExactness(A1, A2)
            assertExactness(A2, A3)
        }
    }
    
    public func assertExactness(_ A: Matrix<R>, _ B: Matrix<R>) {
        assert((B * A).isZero) // Im(A) ⊂ Ker(B)
        
        // TODO assert Im(A) ⊃ Ker(B)
    }
    
    private func log(_ msg: @autoclosure () -> String) {
        // TODO
    }
}

