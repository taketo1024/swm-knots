//
//  GridComplex.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/07/04.
//

import SwiftyMath
import SwiftyHomology

public struct _U: PolynomialIndeterminate {
    public static let degree = -2
    public static var symbol = "U"
}

public typealias _Un = InfiniteVariatePolynomialIndeterminates<_U>

public struct GridComplex: ChainComplexWrapper {
    public typealias InflatedGenerator =
        TensorGenerator<
            MultivariatePolynomialGenerator<_Un>,
            Generator
        >

    public typealias R = 𝐅₂
    public typealias GridDim = _1
    public typealias BaseModule = LinearCombination<InflatedGenerator, R>
    
    public enum Variant {
        case tilde    // [Book] p.72,  Def 4.4.1
        case hat      // [Book] p.80,  Def 4.6.12.
        case minus    // [Book] p.75,  Def 4.6.1
        case filtered // [Book] p.252, Def 13.2.1
    }
    
    public var diagram: GridDiagram
    public var generators: GeneratorSet
    public var chainComplex: ChainComplex1<BaseModule>
    
    private init(_ diagram: GridDiagram, _ generators: GeneratorSet, _ chainComplex: ChainComplex1<BaseModule>) {
        self.diagram = diagram
        self.generators = generators
        self.chainComplex = chainComplex
    }
    
    public init(type: Variant, diagram G: GridDiagram) {
        let generators = GeneratorSet(for: G)
        self.init(type: type, diagram: G, generators: generators)
    }
    
    public init(type: Variant, diagram G: GridDiagram, generators: GeneratorSet) {
        let C = ChainComplex1(
            support: generators.degreeRange,
            sequence:  Self.chain(type: type, diagram: G, generators: generators),
            differential: Self.differential(type: type, diagram: G, generators: generators)
        )
        self.init(G, generators, C)
    }
    
    public static func chain(type: Variant, diagram G: GridDiagram, generators: GeneratorSet) -> ( (Int) -> ModuleObject<Element> ) {
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
                        return Umons.map{ U in U ⊗ x }
                }
            }
            return ModuleObject(basis: gens)
        }
    }
    
    public static func differential(type: Variant, diagram G: GridDiagram, generators: GeneratorSet) -> ( (Int) -> ModuleEnd<Element> ) {
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
        
        func d(_ x: Generator) -> Element {
            let elements = generators
                .adjacents(of: x)
                .compactMap { (y, rect) -> Element.Generator? in
                    U(rect).map{ U in U ⊗ y }
                }
                .countMultiplicities()
                .compactMap { (x, c) in
                    c.isEven ? nil : (x, R.identity)
                }
   
            return Element(elements: elements, keysAreUnique: true)
        }
        
        let cache: CacheDictionary<Generator, Element> = .empty
        
        return { i in
            ModuleEnd.linearlyExtend { t1 -> Element in
                let (m1, x) = t1.factors
                let dx = cache.useCacheOrSet(key: x) { d(x) }
                return dx.mapGenerators { t2 in
                    let (m2, y) = t2.factors
                    return (m1 * m2) ⊗ y
                }
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
        genus(of: G, generators: GeneratorSet(for: G))
    }
    
    public static func genus(of G: GridDiagram, generators: GeneratorSet) -> Int {
        let C = GridComplex(type: .tilde, diagram: G).bigraded
        let H = C.homology()
        let (r1, r2) = C.support!.range
        
        for (j, i) in r2.reversed() * r1.reversed() {
            if !H[i, j].isZero {
                return j
            }
        }
        fatalError()
    }
}


extension TensorGenerator where A == MultivariatePolynomialGenerator<_Un>, B == GridComplex.Generator {
    public var monomial: A {
        factors.0
    }
    
    public var generator: B {
        factors.1
    }

    public var algebraicDegree: Int {
        return -(monomial.exponent.count > 0 ? monomial.exponent[0] : 0)
    }
    
    public var AlexanderDegree: Int {
        return _Un.totalDegree(exponents: monomial.exponent) / 2 + generator.AlexanderDegree
    }
}
