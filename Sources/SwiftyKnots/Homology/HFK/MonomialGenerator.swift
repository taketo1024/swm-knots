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

public struct MonomialGenerator<xn: MPolynomialIndeterminate, A: FreeModuleGenerator>: FreeModuleGenerator {
    public typealias MultiDegree = [Int]
    
    internal let generator: A
    internal let monomialDegree: MultiDegree
    
    internal init(generator: A, monomialDegree: MultiDegree) {
        self.generator = generator
        self.monomialDegree = monomialDegree.droppedLast{ $0 == 0 }
    }
    
    public init<R: Ring>(generator a: A, monomial: MPolynomial<xn, R>) {
        guard let (m, r) = monomial.decompose().first, r == .identity else {
            fatalError("Not a monic monomial: \(monomial)")
        }
        self.init(generator: a, monomialDegree: m.leadMultiDegree)
    }
    
    public var degree: Int {
        return xn.totalDegree(exponents: monomialDegree) + generator.degree
    }
    
    public func asMonomial<R: Ring>(over type: R.Type) -> MPolynomial<xn, R> {
        return MPolynomial(coeffs: [monomialDegree : .identity])
    }
    
    // MEMO: Waiting for parameterized protocol conformance.
    public static func flatten<R>(_ z: FreeModule<A, MPolynomial<xn, R>>) -> FreeModule<MonomialGenerator<xn, A>, R> {
        return z.decomposed().sum { (a, p) in
            p.decompose().sum { (m, r) in
                let x = MonomialGenerator(generator: a, monomial: m)
                return FreeModule([x : r])
            }
        }
    }
    
    public static func recover<R: Ring>(_ z: FreeModule<MonomialGenerator<xn, A>, R>) -> FreeModule<A, MPolynomial<xn, R>> {
        return z.decomposed().sum { (x, r) in
            let (a, p) = (x.generator, x.asMonomial(over: R.self))
            return FreeModule([a : r * p])
        }
    }

    public static func generate(from a: A, degree: Int) -> [MonomialGenerator<xn, A>] {
        assert(xn.isFinite)
        return generate(from: a, degree: degree, numberOfIndeterminates: xn.numberOfIndeterminates)
    }
    
    public static func generate(from a: A, degree: Int, numberOfIndeterminates n: Int) -> [MonomialGenerator<xn, A>] {
        assert((0 ..< n).allSatisfy{ i in xn.degree(i) != 0 })
        let diff = degree - a.degree
        
        func multiDegs(_ diff: Int, _ k: Int) -> [[Int]] {
            guard k >= 0 else {
                return (diff == 0) ? [[]] : []
            }
            
            let d_k = xn.degree(k)
            let m = diff.abs / d_k.abs // max exponent of x_k
            return (0 ... m).flatMap { c -> [[Int]] in
                multiDegs(diff - c * d_k, k - 1).map{ $0.appended(c) }
            }
        }
        
        return multiDegs(diff, n - 1).map{ I in MonomialGenerator(generator: a, monomialDegree: I) }
    }
    
    public static func < (a: MonomialGenerator<xn, A>, b: MonomialGenerator<xn, A>) -> Bool {
        return a.degree < b.degree
    }
    
    public var description: String {
        return MonomialGenerator.recover(FreeModule([self : 1])).description
    }
}
