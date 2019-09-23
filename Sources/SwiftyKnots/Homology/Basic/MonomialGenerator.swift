//
//  MonomialGenerator.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/07/04.
//

import SwiftyMath
import SwiftyHomology

// MEMO: Since homology cannot be computed over a multivariate polynomial ring,
// this struct converts each free generator over R[x1, x2, ...] to free generators over R.

public struct MonomialGenerator<xn: MPolynomialIndeterminate>: FreeModuleGenerator {
    public typealias MultiDegree = [Int]
    public let monomialDegree: MultiDegree
    
    public init(monomialDegree: MultiDegree) {
        self.monomialDegree = monomialDegree.droppedLast{ $0 == 0 }
    }
    
    public init<R: Ring>(monomial: MPolynomial<xn, R>) {
        guard monomial.isMonic && monomial.isMonomial else {
            fatalError("Not a monic monomial: \(monomial)")
        }
        self.init(monomialDegree: monomial.leadMultiDegree)
    }
    
    public static var identity: MonomialGenerator<xn> {
        return .init(monomialDegree: [])
    }
    
    public var degree: Int {
        return xn.totalDegree(exponents: monomialDegree)
    }
    
    public func asMonomial<R: Ring>(over type: R.Type) -> MPolynomial<xn, R> {
        return MPolynomial(coeffs: [monomialDegree : .identity])
    }
    
    public static func * (a: MonomialGenerator<xn>, b: MonomialGenerator<xn>) -> MonomialGenerator<xn> {
        return .init(monomialDegree: a.monomialDegree.merging(b.monomialDegree, with: +))
    }

    public static func < (a: MonomialGenerator<xn>, b: MonomialGenerator<xn>) -> Bool {
        return a.degree < b.degree
    }
    
    public var description: String {
        return asMonomial(over: 𝐙.self).description
    }
}

// MEMO: Waiting for parameterized extension on FreeModule.
public func splitMonomials<xn, A, R>(_ z: FreeModule<A, MPolynomial<xn, R>>) -> FreeModule<TensorGenerator<MonomialGenerator<xn>, A>, R> {
    return z.decomposed().sum { (a, p) in
        p.decomposed().sum { (m, r) in
            let t = TensorGenerator(MonomialGenerator<xn>(monomialDegree: m), a)
            return r * .wrap(t)
        }
    }
}

// MEMO: Waiting for parameterized extension on FreeModule.
public func combineMonomials<xn, A, R>(_ z: FreeModule<TensorGenerator<MonomialGenerator<xn>, A>, R>) -> FreeModule<A, MPolynomial<xn, R>> {
    return z.decomposed().sum { (x, r) in
        let (p, a) = (x.factors.0.asMonomial(over: R.self), x.factors.1)
        return (r * p) * .wrap(a)
    }
}

public func *<xn, A, R>(p: MPolynomial<xn, R>, z: FreeModule<TensorGenerator<MonomialGenerator<xn>, A>, R>) -> FreeModule<TensorGenerator<MonomialGenerator<xn>, A>, R> {
    p.decomposed().sum { (m, a) -> FreeModule<TensorGenerator<MonomialGenerator<xn>, A>, R> in
        a * z.mapGenerators{ (t: TensorGenerator<MonomialGenerator<xn>, A>) in
            let prod = MonomialGenerator<xn>(monomialDegree: m) * t.factors.0
            return TensorGenerator(prod, t.factors.1)
        }
    }
}
