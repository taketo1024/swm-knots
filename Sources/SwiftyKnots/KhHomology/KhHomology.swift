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
    public func KhChainComplexBase<R: EuclideanRing>(_ type: R.Type, reduced: Bool = false, normalized: Bool = true) -> ModuleGrid2<KhTensorElement, R> {
        
        let (n, n⁺, n⁻) = (crossingNumber, crossingNumber⁺, crossingNumber⁻)
        
        let name = "CKh(\(self.name); \(R.symbol))"
        let cube = self.KhCube
        
        let list = (0 ... n).flatMap { (i) -> [(Int, Int, [KhTensorElement]?)] in
            let basis = !reduced ? cube.basis(degree: i) : cube.reducedBasis(degree: i)
            return basis.group(by: { $0.degree }).map{ (j, basis) in (i, j, basis) }
        }
        
        let base = ModuleGrid2<KhTensorElement, R>(name: name, default: .zeroModule, list: list)
        return normalized ? base.shifted(-n⁻, n⁺ - 2 * n⁻) : base
    }
    
    public func KhChainComplex<R: EuclideanRing>(_ type: R.Type, reduced: Bool = false, normalized: Bool = true) -> ChainComplex2<KhTensorElement, R> {
        typealias C = ChainComplex2<KhTensorElement, R>
        let base = KhChainComplexBase(type, reduced: reduced, normalized: normalized)
        let d = C.Differential(bidegree: (1, 0)) { (_, _, x) in self.KhCube.d(x) }
        return C(base: base, differential: d)
    }
    
    public func KhHomology<R: EuclideanRing>(_ type: R.Type, reduced: Bool = false, normalized: Bool = true) -> ModuleGrid2<KhTensorElement, R> {
        let name = "Kh(\(self.name); \(R.symbol))"
        let C = self.KhChainComplex(R.self, reduced: reduced, normalized: normalized)
        return C.homology(name: name)
    }
    
    public func KhLeeHomology<R: EuclideanRing>(_ type: R.Type) -> ModuleGrid2<KhTensorElement, R> {
        typealias C = ChainComplex2<KhTensorElement, R>
        let name = "KhLee(\(self.name); \(R.symbol))"
        let base = KhHomology(type)
        let d = C.Differential(bidegree: (1, 4)) { (_, _, x) in
            self.KhCube.d_Lee(x)
        }
        return ChainComplex2(base: base, differential: d).homology(name: name)
    }
}

public extension ObjectGrid where Dim == _2, Object: SimpleModuleStructureType, Object.A == KhTensorElement {
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
            let a = R(from: (-1).pow(i) * s.rank )
            return a * q.pow(j)
        }
    }
}

/*
extension KhHomology: Codable where R: Codable {
    enum CodingKeys: String, CodingKey {
        case link, H
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.link = try c.decode(Link.self, forKey: .link)
        self.H = try c.decode(Inner.self, forKey: .H)
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(link, forKey: .link)
        try c.encode(H, forKey: .H)
    }
}
*/
