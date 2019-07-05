//
//  GridComplex.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/07/04.
//

import SwiftyMath
import SwiftyHomology

// TODO move to SwiftyMath
extension MPolynomial {
    public static func indeterminate(_ i: Int) -> MPolynomial {
        return .init(coeffs: [[0].repeated(i) + [1] : R.identity] )
    }
}

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
    
    func flatten(numberOfIndeterminants n: Int) -> ChainComplex1<FreeModule<MonomialGenerator<_Un, GridDiagram.Generator>, 𝐙₂>> {
        typealias R = 𝐙₂
        typealias X = MonomialGenerator<_Un, GridDiagram.Generator>
        typealias Base = FreeModule<X, R>
        
        let iMax = grid.supportedCoords.map{ $0[0] }.max()!
        return ChainComplex1<Base>.descending(
            supported: grid.supportedCoords.map{ $0[0] },
            sequence: { i -> ModuleObject<Base> in
                guard i <= iMax else {
                    return .zeroModule
                }
                
                let above = (0 ... (iMax - i) / 2).flatMap { k in self[i + 2 * k].generators }
                let gens = above.flatMap { e -> [Base.Generator] in
                    let x = e.decomposed()[0].0
                    return Base.Generator.generate(from: x, degree: i, numberOfIndeterminates: n)
                }
                return ModuleObject<Base>(basis: gens)
            },
            differential: { i -> ModuleEnd<Base> in
                let d = self.differential[i]
                return ModuleEnd { (z: Base) in
                    let w = d.applied(to: X.recover(z))
                    return X.flatten(w)
                }
            }
        )
    }
}
