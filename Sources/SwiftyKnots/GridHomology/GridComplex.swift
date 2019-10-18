//
//  GridComplex.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/07/04.
//

import SwiftyMath
import SwiftyHomology

public struct _U: PolynomialIndeterminate {
    public static let degree = 2
    public static var symbol = "U"
}

public typealias _Un = InfiniteVariatePolynomialIndeterminates<_U>

public typealias GridComplex = ChainComplex1<FreeModule<TensorGenerator<MultivariatePolynomialGenerator<_Un>, GridDiagram.Generator>, 𝐙₂>>

public enum GridComplexType {
    case tilde    // [Book] p.72,  Def 4.4.1
    case hat      // [Book] p.80,  Def 4.6.12.
    case minus    // [Book] p.75,  Def 4.6.1
    case filtered // [Book] p.252, Def 13.2.1
}

extension GridComplex where GridDim == _1, BaseModule: FreeModuleType, BaseModule.Generator == TensorGenerator<MultivariatePolynomialGenerator<_Un>, GridDiagram.Generator>, BaseModule.BaseRing == 𝐙₂ {
    public init(type: GridComplexType, diagram G: GridDiagram) {
        let generators = GridComplexGenerators(for: G)
        self.init(type: type, diagram: G, generators: generators)
    }
    
    public init(type: GridComplexType, diagram G: GridDiagram, generators: GridComplexGenerators, filter: @escaping (Element.Generator) -> Bool = { _ in true }) {
        self.init(
            supported:    generators.degreeRange,
            sequence:     GridComplex.chain(type: type, diagram: G, generators: generators, filter: filter),
            differential: GridComplex.differential(type: type, diagram: G, generators: generators, filter: filter)
        )
    }
    
    private static func chain(type: GridComplexType, diagram G: GridDiagram, generators: GridComplexGenerators, filter: @escaping (Element.Generator) -> Bool) -> ( (Int) -> ModuleObject<Element> ) {
        let iMax = generators.degreeRange.upperBound
        
        let n = G.gridNumber
        let numberOfIndeterminates: Int = {
            switch type {
            case .tilde:    return 0
            case .hat:      return n - 1
            case .minus:    return n
            case .filtered: return n
            }
        }()
        
        return { i -> ModuleObject<Element> in
            guard i <= iMax else {
                return .zeroModule
            }
            
            let gens = (0 ... (iMax - i) / 2).flatMap { k in
                generators
                    .filter { $0.degree == i + 2 * k }
                    .parallelFlatMap { x -> [Element.Generator] in
                        let indeterminates = Array(0 ..< numberOfIndeterminates)
                        let Umons = MultivariatePolynomialGenerator<_Un>.monomials(ofTotalExponent: k, usingIndeterminates: indeterminates)
                        return Umons.compactMap{ U in
                            let t = U ⊗ x
                            return filter(t) ? t : nil
                        }
                }
            }
            return ModuleObject(basis: gens)
        }
    }
    
    private static func differential(type: GridComplexType, diagram G: GridDiagram, generators: GridComplexGenerators, filter: @escaping (Element.Generator) -> Bool) -> ( (Int) -> ModuleEnd<Element> ) {
        let (Os, Xs) = (G.Os, G.Xs)
        let U: (GridDiagram.Rect) -> MultivariatePolynomialGenerator<_Un>? = { rect in
            switch type {
            case .tilde:
                return (rect.intersects(Xs) || rect.intersects(Os))
                        ? nil : .identity
            case .hat:
                return (rect.intersects(Xs) || rect.contains(Os.last!))
                        ? nil : .init( Os.map { O in rect.contains(O) ? 1 : 0 } )
            case .minus:
                return rect.intersects(Xs)
                        ? nil : .init( Os.map { O in rect.contains(O) ? 1 : 0 } )
            case .filtered:
                return .init( Os.map { O in rect.contains(O) ? 1 : 0 } )
            }
        }
        
        return { i in
            ModuleEnd.linearlyExtend { t -> Element in
                let (m, x) = t.factors
                return generators.adjacents(of: x).parallelFlatMap { y -> [Element] in
                    G.emptyRectangles(from: x, to: y).compactMap { rect -> Element? in
                        if let Us = U(rect) {
                            let ty = (m * Us) ⊗ y
                            return filter(ty) ? .wrap(ty) : nil
                        } else {
                            return nil
                        }
                    }
                }.sumAll()
            }
        }
    }
    
    public static func genus(of G: GridDiagram) -> Int {
        genus(of: G, generators: GridComplexGenerators(for: G))
    }
    
    public static func genus(of G: GridDiagram, generators: GridComplexGenerators) -> Int {
        let C = GridComplex(type: .tilde, diagram: G)
        let H = C.asBigraded { x in x.AlexanderDegree }.homology
        let M = generators.degreeRange
        let A = generators.map{ $0.AlexanderDegree }.range!
        
        for (j, i) in A.reversed() * M.reversed() {
            if !H[i, j].isZero {
                return j
            }
        }
        fatalError()
    }
}


extension TensorGenerator where A == MultivariatePolynomialGenerator<_Un>, B == GridDiagram.Generator {
    public var algebraicDegree: Int {
        let m = factors.0 // MultivariatePolynomialGenerator<_Un>
        return -(m.exponent.indices.contains(0) ? m.exponent[0] : 0)
    }
    
    public var AlexanderDegree: Int {
        let m = factors.0 // MultivariatePolynomialGenerator<_Un>
        let x = factors.1 // GridDiagram.Generator
        return _Un.totalDegree(exponents: m.exponent) / 2 + x.AlexanderDegree
    }
}
