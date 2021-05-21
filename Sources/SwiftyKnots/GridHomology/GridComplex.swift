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

public typealias _Un = EnumeratedPolynomialIndeterminates<_U, anySize>

public struct GridComplex: ChainComplexType {
    public typealias R = 𝐅₂
    public typealias T = TensorGenerator<
        MonomialAsGenerator<_Un>,
        Generator
    >

    public typealias Index = Int
    public typealias BaseModule = LinearCombination<R, T>
    public typealias Differential = ChainMap<Self, Self>
    
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
    
    public init(type: Variant, diagram G: GridDiagram, useCache: Bool = false) {
        let generators = GeneratorSet(for: G)
        self.init(type: type, diagram: G, generators: generators)
    }
    
    public init(type: Variant, diagram G: GridDiagram, generators: GeneratorSet, useCache: Bool = false) {
        let C = ChainComplex1(
            grid: Self.chain(type: type, diagram: G, generators: generators),
            degree: -1,
            differential: Self.differential(type: type, diagram: G, generators: generators, useCache: useCache)
        )
        self.init(G, generators, C)
    }
    
    public subscript(i: Int) -> ModuleStructure<BaseModule> {
        chainComplex[i]
    }
    
    public var differential: Differential {
        ChainMap( chainComplex.differential )
    }
    
    static func chain(type: Variant, diagram G: GridDiagram, generators: GeneratorSet) -> ( (Int) -> ModuleStructure<BaseModule> ) {
        typealias P = MultivariatePolynomial<R, _Un>
        
        let n = G.gridNumber
        let numberOfIndeterminates: Int = {
            switch type {
            case .tilde:    return 0
            case .hat:      return n - 1
            case .minus:    return n
            case .filtered: return n
            }
        }()
        
        let iMax = generators.MaslovDegreeRange.upperBound

        return { i -> ModuleStructure<BaseModule> in
            guard i <= iMax else {
                return .zeroModule
            }
            
            let gens = (0 ... (iMax - i) / 2).flatMap { k in
                generators
                    .filter { $0.degree == i + 2 * k }
                    .parallelFlatMap { x -> [T] in
                        let mons = P.monomials(ofDegree: -2 * k, usingIndeterminates: 0 ..< numberOfIndeterminates)
                        return mons.map { mon in
                            .init(exponent: mon.leadExponent) ⊗ x
                        }
                }
            }
            return ModuleStructure(generators: gens)
        }
    }
    
    static func differential(type: Variant, diagram G: GridDiagram, generators: GeneratorSet, useCache: Bool) -> ( (Int) -> ModuleEnd<BaseModule> ) {
        
        let n = G.gridNumber
        let rects = generators.rects
        let rectCond = { (r: GridDiagram.Rect) -> Bool in
            switch type {
            case .tilde:
                return (!rects[r].intersects(.X) && !rects[r].intersects(.O))
            case .hat:
                return (!rects[r].intersects(.X) && !rects[r].intersects(.O, n - 1))
            case .minus:
                return !rects[r].intersects(.X)
            case .filtered:
                return true
            }
        }
        
        func d(_ x: Generator) -> BaseModule {
            let ys = generators
                .adjacents(of: x, with: rectCond)
                .map { (y, r) -> BaseModule.Generator in
                    if !rects[r].intersects(.O) {
                        return .unit ⊗ y
                    } else {
                        let Uexp = rects[r].intersections(.O)
                        return .init(exponent: Uexp) ⊗ y
                    }
                }
                
            return BaseModule(
                elements: ys.map{ y in (y, R.identity) },
                generatorsAreUnique: ys.isUnique
            )
        }
        
        let cache: Cache<Generator, BaseModule> = .empty
        
        return { i in
            ModuleEnd.linearlyExtend { t1 -> BaseModule in
                let (m1, x) = t1.factors
                let dx = useCache
                    ? cache.getOrSet(key: x) { d(x) }
                    : d(x)
                
                if m1 == .unit {
                    return dx
                } else {
                    return dx.mapGenerators { t2 in
                        let (m2, y) = t2.factors
                        return (m1 * m2) ⊗ y
                    }
                }
            }
        }
    }
    
    public var bigraded: ChainComplex2<BaseModule> {
        chainComplex.asBigraded { summand in
            summand.generator.elements.anyElement!.key.AlexanderDegree
        }
    }
    
    public func shifted(_ shift: Index) -> GridComplex {
        .init(diagram, generators, chainComplex.shifted(shift))
    }
    
    public static func genus(of G: GridDiagram) -> Int {
        genus(of: G, generators: GeneratorSet(for: G))
    }
    
    public static func genus(of G: GridDiagram, generators: GeneratorSet) -> Int {
        let C = GridComplex(type: .tilde, diagram: G).bigraded
        let H = C.homology()
        let (r1, r2) = (generators.MaslovDegreeRange, generators.AlexanderDegreeRange)
        
        for (j, i) in r2.reversed() * r1.reversed() {
            if !H[i, j].isZero {
                return j
            }
        }
        fatalError()
    }
}


extension TensorGenerator where A == MonomialAsGenerator<_Un>, B == GridComplex.Generator {
    public var algebraicDegree: Int {
        return -left.exponent[0]
    }
    
    public var AlexanderDegree: Int {
        return _Un.degreeOfMonomial(withExponent: left.exponent) / 2 + right.AlexanderDegree
    }
}
