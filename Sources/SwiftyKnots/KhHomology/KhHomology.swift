//
//  KhHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath
import SwiftyHomology

public extension Link {
    public func KhChainComplexBase<R: EuclideanRing>(_ type: R.Type, reduced: Bool = false, normalized: Bool = true) -> ModuleGrid2<KhBasisElement, R> {
        
        let (n, n⁺, n⁻) = (crossingNumber, crossingNumber⁺, crossingNumber⁻)
        
        let name = "CKh(\(self.name); \(R.symbol))"
        let cube = self.KhCube
        
        let list = (0 ... n).flatMap { (i) -> [(Int, Int, [KhBasisElement]?)] in
            let basis = !reduced ? cube.basis(degree: i) : cube.reducedBasis(degree: i)
            return basis.group(by: { $0.degree }).map{ (j, basis) in (i, j, basis) }
        }
        
        let base = ModuleGrid2<KhBasisElement, R>(name: name, list: list, default: .zeroModule)
        return normalized ? base.shifted(-n⁻, n⁺ - 2 * n⁻) : base
    }
    
    public func KhChainComplex<R: EuclideanRing>(_ type: R.Type, reduced: Bool = false, normalized: Bool = true) -> ChainComplex2<KhBasisElement, R> {
        typealias C = ChainComplex2<KhBasisElement, R>
        let base = KhChainComplexBase(type, reduced: reduced, normalized: normalized)
        let d = ChainMap2(bidegree: (1, 0)) { (_, _) in self.KhCube.d(R.self) }
        return C(base: base, differential: d)
    }
    
    public func KhHomology<R: EuclideanRing>(_ type: R.Type, reduced: Bool = false, normalized: Bool = true) -> ModuleGrid2<KhBasisElement, R> {
        let name = "Kh(\(self.name); \(R.symbol))"
        let C = self.KhChainComplex(R.self, reduced: reduced, normalized: normalized)
        return C.homology(name: name)
    }
    
    public func KhHomology<R: EuclideanRing & Codable>(_ type: R.Type, useCache: Bool) -> ModuleGrid2<KhBasisElement, R> {
        if useCache {
            let id = "Kh_\(name)_\(R.symbol)"
            return Storage.useCache(id) { KhHomology(R.self) }
        } else {
            return KhHomology(R.self)
        }
    }
    
    public func KhLeeHomology<R: EuclideanRing>(_ type: R.Type) -> ModuleGrid2<KhBasisElement, R> {
        typealias C = ChainComplex2<KhBasisElement, R>
        let name = "KhLee(\(self.name); \(R.symbol))"
        let base = KhHomology(type)
        let d = ChainMap2(bidegree: (1, 4)) { (_, _) in self.KhCube.d_Lee(R.self) }
        return ChainComplex2(base: base, differential: d).homology(name: name)
    }
}

public extension GridN where n == _2, Object: _ModuleObject, Object.A == KhBasisElement {
    public var bandWidth: Int {
        return bidegrees.map{ (i, j) in j - 2 * i }.unique().count
    }
    
    public var isDiagonal: Bool {
        return bandWidth == 1
    }
    
    public var isHThin: Bool {
        return bandWidth <= 2
    }
    
    public var isHThick: Bool {
        return !isHThin
    }
    
    public var qEulerCharacteristic: LaurentPolynomial<R, JonesPolynomial_q> {
        let q = LaurentPolynomial<R, JonesPolynomial_q>.indeterminate
        return bidegrees.sum { (i, j) -> LaurentPolynomial<R, JonesPolynomial_q> in
            let s = self[i, j]!
            let a = R(from: (-1).pow(i) * s.entity.rank )
            return a * q.pow(j)
        }
    }
}
