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

extension GridDiagram {
    // MEMO: GC-tilde. [Book] p.72, Def 4.4.1
    public func fullyBlockedGridComplex() -> ChainComplex1<FreeModule<GridDiagram.Generator, 𝐙₂>> {
        typealias R = 𝐙₂
        
        let (Os, Xs) = (self.Os, self.Xs)
        return _gridComplex { x -> FreeModule<GridDiagram.Generator, R> in
            self.generators(ofDegree: x.degree - 1).sum { y in
                let c = self.emptyRectangles(from: x, to: y).exclude{ r in
                    r.intersects(Xs) || r.intersects(Os)
                }.count
                return R(from: c) * .wrap(y)
            }
        }
    }
    
    // MEMO: GC-hat. [Book] p.80, Def 4.6.12.
    // Must consider P = F[U_0 ... U_{n - 2}]
    public func simplyBlockedGridComplex() -> ChainComplex1<FreeModule<GridDiagram.Generator, MPolynomial<_Un, 𝐙₂>>> {
        typealias P = MPolynomial<_Un, 𝐙₂>
        
        let (Os, Xs) = (self.Os, self.Xs)
        let O_last = Os.last!
        
        return _gridComplex { x -> FreeModule<GridDiagram.Generator, P> in
            self.adjacents(x).sum { y in
                let rects = self.emptyRectangles(from: x, to: y).exclude{ r in r.intersects(Xs) || r.contains(O_last) }
                let c = rects.sum { r in
                    Os.enumerated().multiply { (i, O) in r.contains(O) ? P.indeterminate(i) : .identity }
                }
                return c * .wrap(y)
            }
        }
    }
    
    // MEMO: GC^-. [Book] p.75, Def 4.6.1
    public func gridComplex() -> ChainComplex1<FreeModule<GridDiagram.Generator, MPolynomial<_Un, 𝐙₂>>> {
        typealias P = MPolynomial<_Un, 𝐙₂>
        
        let (Os, Xs) = (self.Os, self.Xs)
        return _gridComplex { x -> FreeModule<GridDiagram.Generator, P> in
            self.adjacents(x).sum { y in
                let rects = self.emptyRectangles(from: x, to: y).exclude{ r in r.intersects(Xs) }
                let c = rects.sum { r in
                    Os.enumerated().multiply { (i, O) in r.contains(O) ? P.indeterminate(i) : .identity }
                }
                return c * .wrap(y)
            }
        }
    }
    
    // MEMO: 𝓖𝓒^-. [Book] p.252, Def 13.2.1
    public func filteredGridComplex() -> ChainComplex1<FreeModule<GridDiagram.Generator, MPolynomial<_Un, 𝐙₂>>> {
        typealias P = MPolynomial<_Un, 𝐙₂>
        
        let Os = self.Os
        return _gridComplex { x -> FreeModule<GridDiagram.Generator, P> in
            self.adjacents(x).sum { y in
                let rects = self.emptyRectangles(from: x, to: y)
                let c = rects.sum { r in
                    Os.enumerated().multiply { (i, O) in r.contains(O) ? P.indeterminate(i) : .identity }
                }
                return c * .wrap(y)
            }
        }
    }
    
    private func _gridComplex<R: Ring>(differential: @escaping (GridDiagram.Generator) -> FreeModule<GridDiagram.Generator, R>) -> ChainComplex1<FreeModule<GridDiagram.Generator, R>> {
        return ChainComplex1.descending(
            supported: degreeRange,
            sequence: { i in ModuleObject(basis: self.generators(ofDegree: i)) },
            differential: { i in ModuleEnd.linearlyExtend(differential) }
        )
    }
}

extension ChainComplex where GridDim == _1, BaseModule == FreeModule<GridDiagram.Generator, MPolynomial<_Un, 𝐙₂>> {
    
    func distributeMonomials(numberOfIndeterminants n: Int) -> ChainComplex1<FreeModule<TensorGenerator<MonomialGenerator<_Un>, GridDiagram.Generator>, 𝐙₂>> {
        typealias R = 𝐙₂
        typealias P = MPolynomial<_Un, R>
        typealias Distributed = FreeModule<TensorGenerator<MonomialGenerator<_Un>, GridDiagram.Generator>, R>
        
        let iMax = grid.supportedCoords.map{ $0[0] }.max()!
        return ChainComplex1<Distributed>.descending(
            supported: grid.supportedCoords.map{ $0[0] },
            sequence: { i -> ModuleObject<Distributed> in
                guard i <= iMax else {
                    return .zeroModule
                }
                
                let above = (0 ... (iMax - i) / 2).flatMap { k in self[i + 2 * k].generators }
                let gens = above.flatMap { e -> [Distributed.Generator] in
                    let x = e.decomposed()[0].0
                    let mons = P.monomials(ofDegree: i - x.degree, usingIndeterminates: (0 ..< n).toArray())
                    return mons.map{ m in TensorGenerator(MonomialGenerator(monomial: m), x) }
                }
                return ModuleObject<Distributed>(basis: gens)
            },
            differential: { i -> ModuleEnd<Distributed> in
                let d = self.differential[i]
                return ModuleEnd { (z: Distributed) in
                    let w = d.applied(to: combineMonomials(z))
                    return SwiftyKnots.splitMonomials(w)
                }
            }
        )
    }
}

private extension TensorGenerator where A == MonomialGenerator<_Un>, B == GridDiagram.Generator {
    var algebraicDegree: Int {
        let m = factors.0 // MonomialGenerator<_Un>
        return -(m.monomialDegree.indices.contains(0) ? m.monomialDegree[0] : 0)
    }
    
    var AlexanderDegree: Int {
        let m = factors.0 // MonomialGenerator<_Un>
        let x = factors.1 // GridDiagram.Generator
        return _Un.totalDegree(exponents: m.monomialDegree) / 2 + x.AlexanderDegree
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
            return
        }
        
        let (iMax, iMin) = (dict.keys.map{ $0[0] }.max()!, dict.keys.map{ $0[0] }.min()!)
        let (jMax, jMin) = (dict.keys.map{ $0[1] }.max()!, dict.keys.map{ $0[1] }.min()!)
        
        let table = Format.table(rows: (iMin ... iMax).toArray(), cols: (jMin ... jMax).toArray(), symbol: "j\\i") { (i, j) -> String in
            let count = dict[[i, j]]?.count ?? 0
            return count > 0 ? "\(count)" : ""
        }
        
        print(table)
    }
}
