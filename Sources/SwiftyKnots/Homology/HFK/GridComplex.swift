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
    public static func tilde(_ G: GridDiagram) -> ChainComplex1<FreeModule<GridDiagram.Generator, 𝐙₂>> {
        typealias R = 𝐙₂
        
        let (Os, Xs) = (G.Os, G.Xs)
        return _gridComplex(G) { rect in
            (rect.intersects(Xs) || rect.intersects(Os))
                ? .zero
                : .identity
        }
    }
    
    // GC-hat. [Book] p.80, Def 4.6.12.
    public static func hat(_ G: GridDiagram) -> GridComplex {
        typealias P = MPolynomial<_Un, 𝐙₂>
        
        let (Os, Xs) = (G.Os, G.Xs)
        let O_last = Os.last!
        
        return _gridComplex(G) { rect in
            (rect.intersects(Xs) || rect.contains(O_last))
                ? .zero
                : Os.enumerated().multiply { (i, O) in rect.contains(O) ? P.indeterminate(i) : .identity }
        }.splitMonomials(numberOfIndeterminants: G.gridNumber - 1)
    }
    
    // GC^-. [Book] p.75, Def 4.6.1
    public static func minus(_ G: GridDiagram) -> GridComplex {
        typealias P = MPolynomial<_Un, 𝐙₂>
        
        let (Os, Xs) = (G.Os, G.Xs)
        return _gridComplex(G) { rect in
            rect.intersects(Xs)
                ? .zero
                : Os.enumerated().multiply { (i, O) in rect.contains(O) ? P.indeterminate(i) : .identity }
        }.splitMonomials(numberOfIndeterminants: G.gridNumber)
    }
    
    // MEMO: 𝓖𝓒^-. [Book] p.252, Def 13.2.1
    public static func filtered(_ G: GridDiagram) -> GridComplex {
        typealias P = MPolynomial<_Un, 𝐙₂>
        
        let Os = G.Os
        return _gridComplex(G) { rect in
            Os.enumerated().multiply {
                (i, O) in rect.contains(O) ? P.indeterminate(i) : .identity
            }
        }.splitMonomials(numberOfIndeterminants: G.gridNumber)
    }
    
    private static func _gridComplex<R: Ring>(_ G: GridDiagram, _ coeff: @escaping (GridDiagram.Rect) -> R) -> ChainComplex1<FreeModule<GridDiagram.Generator, R>> {
        return ChainComplex1.descending(
            supported: G.degreeRange,
            sequence: { i in ModuleObject(basis: G.generators(ofDegree: i)) },
            differential: { i in
                ModuleEnd.linearlyExtend {  x -> FreeModule<GridDiagram.Generator, R> in
                    G.adjacents(x).sum { y in
                        let rects = G.emptyRectangles(from: x, to: y)
                        let c = rects.sum { rect in coeff(rect) }
                        return c * .wrap(y)
                    }
                }
            }
        )
    }
}

extension ChainComplex where GridDim == _1, BaseModule == FreeModule<GridDiagram.Generator, MPolynomial<_Un, 𝐙₂>> {
    func splitMonomials(numberOfIndeterminants n: Int) -> GridComplex {
        typealias R = 𝐙₂
        typealias P = MPolynomial<_Un, R>
        typealias Result = FreeModule<TensorGenerator<MonomialGenerator<_Un>, GridDiagram.Generator>, R>
        
        let iMax = grid.supportedCoords.map{ $0[0] }.max()!
        return ChainComplex1<Result>.descending(
            supported: grid.supportedCoords.map{ $0[0] },
            sequence: { i -> ModuleObject<Result> in
                guard i <= iMax else {
                    return .zeroModule
                }
                
                let above = (0 ... (iMax - i) / 2).flatMap { k in self[i + 2 * k].generators }
                let gens = above.flatMap { e -> [Result.Generator] in
                    let x = e.decomposed()[0].0
                    let mons = P.monomials(ofDegree: i - x.degree, usingIndeterminates: (0 ..< n).toArray())
                    return mons.map{ m in TensorGenerator(MonomialGenerator(monomial: m), x) }
                }
                return ModuleObject<Result>(basis: gens)
            },
            differential: { i -> ModuleEnd<Result> in
                let d = self.differential[i]
                return ModuleEnd { (z: Result) in
                    let w = d.applied(to: combineMonomials(z))
                    return SwiftyKnots.splitMonomials(w)
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
    
    internal var coords: (Int, Int) {
        return (algebraicDegree, AlexanderDegree)
    }
}

extension FreeModule where A == TensorGenerator<MonomialGenerator<_Un>, GridDiagram.Generator> {
    public func groupByDegrees() -> [GridCoords : [FreeModule<GridDiagram.Generator, MPolynomial<_Un, R>>]] {
        var dict: [GridCoords : [FreeModule<GridDiagram.Generator, MPolynomial<_Un, R>>]] = [:]
        for (t, r) in decomposed() {
            let c = [t.algebraicDegree, t.AlexanderDegree]
            let m = combineMonomials(FreeModule([t : r]))
            if dict.contains(key: c) {
                dict[c]!.append(m)
            } else {
                dict[c] = [m]
            }
        }
        return dict
    }
    
    public func printDegrees() {
        let dict = groupByDegrees()
        if dict.isEmpty {
            print("empty")
            return
        }
        
        let (iMax, iMin) = (dict.keys.map{ $0[0] }.max()!, dict.keys.map{ $0[0] }.min()!)
        let (jMax, jMin) = (dict.keys.map{ $0[1] }.max()!, dict.keys.map{ $0[1] }.min()!)
        
        let table = Format.table(rows: (jMin ... jMax).reversed().toArray(), cols: (iMin ... iMax).toArray(), symbol: "j\\i") { (j, i) -> String in
            let count = dict[[i, j]]?.count ?? 0
            return count > 0 ? "\(count)" : ""
        }
        
        print(table)
    }
}
