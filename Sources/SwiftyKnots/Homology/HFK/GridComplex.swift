//
//  GridComplex.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/07/04.
//

import SwiftyMath
import SwiftyHomology

public struct _Un: MPolynomialIndeterminate {
    public static let numberOfIndeterminates = Int.max
    public static func degree(_ i: Int) -> Int {
        return -2
    }
    public static func symbol(_ i: Int) -> String {
        return "U\(Format.sub(i))"
    }
}

public typealias GridComplex = ChainComplex1<FreeModule<TensorGenerator<MonomialGenerator<_Un>, GridDiagram.Generator>, 𝐙₂>>

extension GridComplex {
    // GC-tilde. [Book] p.72, Def 4.4.1
    // MEMO: not a knot invariant.
    public static func tilde(_ G: GridDiagram) -> GridComplex {
        typealias R = 𝐙₂
        
        let (Os, Xs) = (G.Os, G.Xs)
        return _gridComplex(G, 0) { rect in
            (rect.intersects(Xs) || rect.intersects(Os))
                ? nil : .identity
        }
    }
    
    // GC-hat. [Book] p.80, Def 4.6.12.
    public static func hat(_ G: GridDiagram) -> GridComplex {
        typealias P = MPolynomial<_Un, 𝐙₂>
        
        let n = G.gridNumber
        let (Os, Xs) = (G.Os, G.Xs)
        let O_last = Os.last!
        
        return _gridComplex(G, n - 1) { rect in
            (rect.intersects(Xs) || rect.contains(O_last))
                ? nil : .init(monomialDegree: Os.map { O in rect.contains(O) ? 1 : 0 })
        }
    }
    
    // GC^-. [Book] p.75, Def 4.6.1
    public static func minus(_ G: GridDiagram) -> GridComplex {
        typealias P = MPolynomial<_Un, 𝐙₂>
        
        let n = G.gridNumber
        let (Os, Xs) = (G.Os, G.Xs)
        return _gridComplex(G, n) { rect in
            rect.intersects(Xs)
                ? nil : .init(monomialDegree: Os.map { O in rect.contains(O) ? 1 : 0 })
        }
    }
    
    // MEMO: 𝓖𝓒^-. [Book] p.252, Def 13.2.1
    public static func filtered(_ G: GridDiagram) -> GridComplex {
        typealias P = MPolynomial<_Un, 𝐙₂>
        
        let n = G.gridNumber
        let Os = G.Os
        return _gridComplex(G, n) { rect in
            .init(monomialDegree: Os.map { O in rect.contains(O) ? 1 : 0 })
        }
    }
    
    private static func _gridComplex(_ G: GridDiagram, _ n: Int, _ U: @escaping (GridDiagram.Rect) -> MonomialGenerator<_Un>?) -> GridComplex {
        typealias T = TensorGenerator<MonomialGenerator<_Un>, GridDiagram.Generator>
        typealias M = FreeModule<T, 𝐙₂>
        typealias P = MPolynomial<_Un, 𝐙₂>
        
        let range = G.generators.map{ $0.MaslovDegree }.range!
        let iMax = range.max()!
        
        return ChainComplex1.descending(
            supported: range,
            sequence: { i -> ModuleObject<M> in
                guard i <= iMax else {
                    return .zeroModule
                }
                
                let above = (0 ... (iMax - i) / 2).flatMap { k in
                    G.generators.filter{ $0.degree == i + 2 * k }
                }
                let gens = above.flatMap { x -> [T] in
                    let mons = P.monomials(ofDegree: i - x.degree, usingIndeterminates: (0 ..< n).toArray()).map{ m in MonomialGenerator(monomial: m) }
                    return mons.map{ m in T(m, x) }
                }
                return ModuleObject(basis: gens)
            },
            differential: { i in
                // what we are doing here is:
                // d(U^I x) = U^I d(x) = U^I (Σ U^J y) = Σ U^(I+J) y
                ModuleEnd.linearlyExtend { t -> M in
                    let (m0, x) = t.factors
                    let dx = G.generators.adjacents(of: x).flatMap { y  in
                        G.emptyRectangles(from: x, to: y).compactMap { rect in
                            U(rect).map{ T($0, y) }
                        }
                    }
                    return dx.sum { y in
                        .wrap(m0 * y)
                    }
                }
            }
        )
    }
}


extension TensorGenerator where A == MonomialGenerator<_Un>, B == GridDiagram.Generator {
    public var algebraicDegree: Int {
        let m = factors.0 // MonomialGenerator<_Un>
        return -(m.monomialDegree.indices.contains(0) ? m.monomialDegree[0] : 0)
    }
    
    public var AlexanderDegree: Int {
        let m = factors.0 // MonomialGenerator<_Un>
        let x = factors.1 // GridDiagram.Generator
        return _Un.totalDegree(exponents: m.monomialDegree) / 2 + x.AlexanderDegree
    }
    
    public static func * (a: A, t: TensorGenerator<A, B>) -> TensorGenerator<A, B> {
        return .init(a * t.factors.0, t.factors.1)
    }
}

extension GridDiagram {
    public var knotGenus: Int {
        let H = GridComplex.tilde(self).asBigraded { x in x.AlexanderDegree }.homology
        let M = generators.map{ $0.MaslovDegree }.range!
        let A = generators.map{ $0.AlexanderDegree }.range!
        
        for (j, i) in A.reversed() * M.reversed() {
            if !H[i, j].isZero {
                return j
            }
        }
        
        fatalError()
    }
}
