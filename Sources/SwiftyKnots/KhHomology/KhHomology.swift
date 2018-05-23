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
    public func KhChainComplex<R: EuclideanRing>(_ type: R.Type, reduced: Bool = false, normalized: Bool = true, shifted: (Int, Int) = (0, 0)) -> BigradedChainComplex<KhTensorElement, R> {
        return KhChainComplex(KhBasisElement.μ, KhBasisElement.Δ, R.self,
                              reduced: reduced, normalized: normalized, shifted: shifted)
    }
    
    public func KhChainComplex<R: EuclideanRing>(_ μ: @escaping KhBasisElement.Product<R>, _ Δ: @escaping KhBasisElement.Coproduct<R>, _ type: R.Type, reduced: Bool = false, normalized: Bool = true, shifted: (Int, Int) = (0, 0)) -> BigradedChainComplex<KhTensorElement, R> {
        
        let (n, n⁺, n⁻) = (crossingNumber, crossingNumber⁺, crossingNumber⁻)
        
        let name = "CKh(\(self.name); \(R.symbol))"
        let cube = self.KhCube
        
        let list = (0 ... n).flatMap { (i) -> [(Int, Int, [KhTensorElement]?)] in
            let basis = { () -> [KhTensorElement] in
                let basis = !reduced ? cube.basis(degree: i) : cube.reducedBasis(degree: i)
                let shift = (normalized ? n⁺ - 2 * n⁻ : 0) + shifted.1
                return (shift != 0) ? basis.map{ $0.shifted(shift) } : basis
            }()
            return basis.group(by: { $0.degree }).map{ (j, basis) in (i, j, basis) }
        }
        
        let base = BigradedModuleStructure<KhTensorElement, R>(name: name, list: list)
            .shifted( (normalized ? -n⁻ : 0) + shifted.0, 0)
        
        return base.asChainComplex(degree: (1, 0)) { (i, j, x) in
            cube.map(x, μ, Δ)
        }
    }

    public func KhHomology<R: EuclideanRing>(_ type: R.Type, reduced: Bool = false, normalized: Bool = true, shifted: (Int, Int) = (0, 0)) -> BigradedModuleStructure<KhTensorElement, R> {
        return KhHomology(KhBasisElement.μ, KhBasisElement.Δ, R.self,
                          reduced: reduced, normalized: normalized, shifted: shifted)
    }
    
    public func KhHomology<R: EuclideanRing>(_ μ: @escaping KhBasisElement.Product<R>, _ Δ: @escaping KhBasisElement.Coproduct<R>, _ type: R.Type, reduced: Bool = false, normalized: Bool = true, shifted: (Int, Int) = (0, 0)) -> BigradedModuleStructure<KhTensorElement, R> {
        
        let name = "Kh(\(self.name); \(R.symbol))"
        let C = self.KhChainComplex(μ, Δ, R.self, reduced: reduced, normalized: normalized, shifted: shifted)
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
    
    /*
    public var structureCode: String {
        return validDegrees.map{ (i, j) in
            let s = self[i, j]
            let f = (s.rank > 0) ? "0\(Format.sup(s.rank))₍\(Format.sub(i)),\(Format.sub(j))₎" : ""
            let t = s.torsionCoeffs.countMultiplicities().map{ (d, r) in
                "\(d)\(Format.sup(r))₍\(Format.sub(i)),\(Format.sub(j))₎"
            }.joined()
            return f + t
        }.joined()
    }
    */
}

/*
public extension KhHomology where R == 𝐙 {
    public var order2torsionPart: KhHomology<𝐙₂> {
        typealias Kh = KhHomology<𝐙₂>
        let name = "Kh(\(link.name); \(R.symbol))_𝐙₂"
        let summands = (H.offset ... H.topDegree).map { i -> Kh.Summand in
            H[i].subSummands(torsion: 2)
        }
        let Hf = Kh.Inner(name: name, offset: H.offset, summands: summands)
        
        return Kh(link, Hf)
    }
    
}

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
