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

public struct GridComplex: ChainComplexWrapper {
    public typealias R = 𝐙₂
    public typealias GridDim = _1
    public typealias BaseModule = LinearCombination<TensorGenerator<MultivariatePolynomialGenerator<_Un>, GridDiagram.Generator>, R>
    
    public enum Variant {
        case tilde    // [Book] p.72,  Def 4.4.1
        case hat      // [Book] p.80,  Def 4.6.12.
        case minus    // [Book] p.75,  Def 4.6.1
        case filtered // [Book] p.252, Def 13.2.1
    }
    
    public var diagram: GridDiagram
    public var generators: GridComplexGenerators
    public var chainComplex: ChainComplex1<BaseModule>
    
    private init(_ diagram: GridDiagram, _ generators: GridComplexGenerators, _ chainComplex: ChainComplex1<BaseModule>) {
        self.diagram = diagram
        self.generators = generators
        self.chainComplex = chainComplex
    }
    
    public init(type: Variant, diagram G: GridDiagram) {
        let generators = GridComplexGenerators(for: G)
        self.init(type: type, diagram: G, generators: generators)
    }
    
    public init(type: Variant, diagram G: GridDiagram, generators: GridComplexGenerators, filter: @escaping (Element.Generator) -> Bool = { _ in true }) {
        let C = ChainComplex1(
            support: generators.degreeRange,
            sequence:  Self.chain(type: type, diagram: G, generators: generators, filter: filter),
            differential: Self.differential(type: type, diagram: G, generators: generators, filter: filter)
        )
        self.init(G, generators, C)
    }
    
    private static func chain(type: Variant, diagram G: GridDiagram, generators: GridComplexGenerators, filter: @escaping (Element.Generator) -> Bool) -> ( (Int) -> ModuleObject<Element> ) {
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
    
    private static func differential(type: Variant, diagram G: GridDiagram, generators: GridComplexGenerators, filter: @escaping (Element.Generator) -> Bool) -> ( (Int) -> ModuleEnd<Element> ) {
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
    
    public var bigraded: ChainComplex2<BaseModule> {
        let A = generators.map{ $0.AlexanderDegree }.range!
        return chainComplex.asBigraded(secondarySupport: A) { x in x.AlexanderDegree }
    }
    
    public func shifted(_ shift: Coords) -> GridComplex {
        .init(diagram, generators, chainComplex.shifted(shift))
    }
    
    public static func genus(of G: GridDiagram) -> Int {
        genus(of: G, generators: GridComplexGenerators(for: G))
    }
    
    public static func genus(of G: GridDiagram, generators: GridComplexGenerators) -> Int {
        let C = GridComplex(type: .tilde, diagram: G).bigraded
        let H = C.homology
        let (r1, r2) = C.support!.range
        
        for (j, i) in r2.reversed() * r1.reversed() {
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
