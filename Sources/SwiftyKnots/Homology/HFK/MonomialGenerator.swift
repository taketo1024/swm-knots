//
//  MonomialGenerator.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/07/04.
//

import SwiftyMath
import SwiftyHomology

extension MPolynomial {
    public static func indeterminate(_ i: Int) -> MPolynomial {
        return .init(coeffs: [[0].repeated(i) + [1] : R.identity] )
    }

    public static func monomial(ofMultiDegree I: MultiDegree) -> MPolynomial<xn, R> {
        return .init(coeffs: [I: .identity])
    }

    public static func generateMonomials(ofDegree degree: Int) -> [MPolynomial<xn, R>] {
        assert(xn.isFinite)
        return generateMonomials(ofDegree: degree, usingIndeterminates: xn.numberOfIndeterminates)
    }
    
    public static func generateMonomials(ofDegree degree: Int, usingIndeterminates n: Int) -> [MPolynomial<xn, R>] {
        assert((0 ..< n).allSatisfy{ i in xn.degree(i) != 0 })
        
        func multiDegs(_ degree: Int, _ i: Int) -> [[Int]] {
            guard i >= 0 else {
                return (degree == 0) ? [[]] : []
            }
            
            let d = xn.degree(i)
            let m = degree.abs / d.abs // max exponent of x_i
            return (0 ... m).flatMap { c -> [[Int]] in
                multiDegs(degree - c * d, i - 1).map{ $0.appended(c) }
            }
        }
        
        return multiDegs(degree, n - 1).map{ I in .monomial(ofMultiDegree: I) }
    }
}

public struct Tensor2<A, B>: FreeModuleGenerator where A: FreeModuleGenerator, B: FreeModuleGenerator {
    private let left: A
    private let right: B
    
    public init(_ a: A, _ b: B) {
        self.left = a
        self.right = b
    }
    
    public var factors: (A, B) {
        return (left, right)
    }
    
    public var degree: Int {
        return left.degree + right.degree
    }
    
    public static func < (a: Tensor2<A, B>, b: Tensor2<A, B>) -> Bool {
        return [a.left.degree, a.right.degree] < [b.left.degree, b.right.degree]
    }
    
    public var description: String {
        return "\(left.description)⊗\(right.description)"
    }
}

// MEMO: Since homology cannot be computed over a multivariate polynomial ring,
// this struct converts each free generator over R[x1, x2, ...] to free generators over R.

public struct MonomialGenerator<xn: MPolynomialIndeterminate>: FreeModuleGenerator {
    public typealias MultiDegree = [Int]
    internal let monomialDegree: MultiDegree
    
    public init(monomialDegree: MultiDegree) {
        self.monomialDegree = monomialDegree.droppedLast{ $0 == 0 }
    }
    
    public init<R: Ring>(monomial: MPolynomial<xn, R>) {
        guard let (m, r) = monomial.decompose().first, r == .identity else {
            fatalError("Not a monic monomial: \(monomial)")
        }
        self.init(monomialDegree: m.leadMultiDegree)
    }
    
    public var degree: Int {
        return xn.totalDegree(exponents: monomialDegree)
    }
    
    public func asMonomial<R: Ring>(over type: R.Type) -> MPolynomial<xn, R> {
        return MPolynomial(coeffs: [monomialDegree : .identity])
    }
    
    public static func * (a: MonomialGenerator<xn>, b: MonomialGenerator<xn>) -> MonomialGenerator<xn> {
        func merge(_ I: MultiDegree, _ J: MultiDegree) -> MultiDegree {
            let l = max(I.count, J.count)
            return (0 ..< l).map{ i in (I.indices.contains(i) ? I[i] : 0) + (J.indices.contains(i) ? J[i] : 0) }
        }
        return .init(monomialDegree: merge(a.monomialDegree, b.monomialDegree))
    }
    
    public static func < (a: MonomialGenerator<xn>, b: MonomialGenerator<xn>) -> Bool {
        return a.degree < b.degree
    }
    
    public var description: String {
        return asMonomial(over: 𝐙.self).description
    }
}

// MEMO: Waiting for parameterized extension on FreeModule.
public func distributeMonomials<xn, A, R>(_ z: FreeModule<A, MPolynomial<xn, R>>) -> FreeModule<Tensor2<MonomialGenerator<xn>, A>, R> {
    return z.decomposed().sum { (a, p) in
        p.decompose().sum { (m, r) in
            let t = Tensor2(MonomialGenerator(monomial: m), a)
            return FreeModule([t : r])
        }
    }
}

// MEMO: Waiting for parameterized extension on FreeModule.
public func combineMonomials<xn, A, R>(_ z: FreeModule<Tensor2<MonomialGenerator<xn>, A>, R>) -> FreeModule<A, MPolynomial<xn, R>> {
    return z.decomposed().sum { (x, r) in
        let (p, a) = (x.factors.0.asMonomial(over: R.self), x.factors.1)
        return FreeModule([a : r * p])
    }
}

public func *<xn, A, R>(p: MPolynomial<xn, R>, z: FreeModule<Tensor2<MonomialGenerator<xn>, A>, R>) -> FreeModule<Tensor2<MonomialGenerator<xn>, A>, R> {
    p.decompose().sum { (m, a) -> FreeModule<Tensor2<MonomialGenerator<xn>, A>, R> in
        a * z.mapGenerators{ (t: Tensor2<MonomialGenerator<xn>, A>) in
            let prod = MonomialGenerator(monomial: m) * t.factors.0
            return Tensor2(prod, t.factors.1)
        }
    }
}
