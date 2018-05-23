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
    public func KhChainComplexBase<R: EuclideanRing>(_ type: R.Type, reduced: Bool = false, normalized: Bool = true) -> BigradedModuleStructure<KhTensorElement, R> {
        
        let (n, n⁺, n⁻) = (crossingNumber, crossingNumber⁺, crossingNumber⁻)
        
        let name = "CKh(\(self.name); \(R.symbol))"
        let cube = self.KhCube
        
        let list = (0 ... n).flatMap { (i) -> [(Int, Int, [KhTensorElement]?)] in
            let basis = !reduced ? cube.basis(degree: i) : cube.reducedBasis(degree: i)
            return basis.group(by: { $0.degree }).map{ (j, basis) in (i, j, basis) }
        }
        
        let base = BigradedModuleStructure<KhTensorElement, R>(name: name, list: list)
        return normalized ? base.shifted(-n⁻, n⁺ - 2 * n⁻) : base
    }
    
    public func KhChainComplex<R: EuclideanRing>(_ type: R.Type, reduced: Bool = false, normalized: Bool = true) -> BigradedChainComplex<KhTensorElement, R> {
        let base = KhChainComplexBase(type, reduced: reduced, normalized: normalized)
        return base.asChainComplex(degree: (1, 0)) { (_, _, x) in self.KhCube.d(x) }
    }
    
    public func KhHomology<R: EuclideanRing>(_ type: R.Type, reduced: Bool = false, normalized: Bool = true) -> BigradedModuleStructure<KhTensorElement, R> {
        let name = "Kh(\(self.name); \(R.symbol))"
        let C = self.KhChainComplex(R.self, reduced: reduced, normalized: normalized)
        return C.homology(name: name)
    }
}

public extension BigradedModuleStructure where Dim == _2, A == KhTensorElement {
    public var bandWidth: Int {
        return nonZeroDegrees.map{ (i, j) in j - 2 * i }.unique().count
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
        return nonZeroDegrees.sum { (i, j) -> LaurentPolynomial<R, JonesPolynomial_q> in
            R(from: (-1).pow(i) * self[i, j]!.summands.count{ $0.isFree }) * q.pow(j)
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
