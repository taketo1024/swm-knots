//
//  RasmussenInvariant.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/05/31.
//

import SwiftyMath

private struct _t: PolynomialIndeterminate {
    static var symbol = "t"
    static var degree = -4
}

extension Link {
    public var RasmussenInvariant: Int {
        RasmussenInvariant(𝐐.self)
    }
    
    public func RasmussenInvariant<F: Field>(_ type: F.Type) -> Int {
        assert(components.count == 1) // currently supports only knots.
        
        typealias R = Polynomial<_t, F> // R = F[t], deg(t) = -4.
        
        let L = self
        let C = KhovanovComplex(link: L, h: .zero, t: R.indeterminate)
        let H0 = C.homology[0]
        
        let q = H0.summands.filter{ $0.isFree }.map { summand in
            summand.generator.generators.map { x in x.degree }.min()!
        }.max()!
        
        let (n⁺, n⁻) = (L.crossingNumber⁺, L.crossingNumber⁻)
        let qShift = n⁺ - 2 * n⁻

        return q + qShift - 1
    }
}
