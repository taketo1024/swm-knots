//
//  KhComplex.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/10/10.
//

import SwiftyMath
import SwiftyHomology

public struct KhovanovComplex<R: Ring>: ChainComplexType {
    public typealias Index = Int
    public typealias BaseModule = IndexedModule<Cube.Coords, LinearCombination<R, MultiTensorGenerator<KhovanovAlgebraGenerator>>>
    public typealias Object = ModuleObject<BaseModule>
    public typealias Differential = ChainMap<Index, BaseModule, BaseModule>
    
    public let type: KhovanovAlgebra<R>
    public let link: Link
    public let cube: KhovanovCube<R>
    public let chainComplex: ChainComplex1<BaseModule>
    public let normalized: Bool
    
    private init(_ type: KhovanovAlgebra<R>, _ link: Link, _ cube: KhovanovCube<R>, _ chainComplex: ChainComplex1<BaseModule>, _ normalized: Bool) {
        self.type = type
        self.link = link
        self.cube = cube
        self.chainComplex = chainComplex
        self.normalized = normalized
    }
    
    public init(type: KhovanovAlgebra<R> = .Khovanov, link: Link, normalized: Bool = true) {
        let n⁻ = link.crossingNumber⁻
        let cube = KhovanovCube(type: type, link: link)
        let chainComplex = cube.asChainComplex().shifted(normalized ? -n⁻ : 0)
        self.init(type, link, cube, chainComplex, normalized)
    }
    
    public subscript(i: Int) -> ModuleObject<BaseModule> {
        chainComplex[i]
    }
    
    public var differential: Differential {
        chainComplex.differential
    }
    
    public func shifted(_ shift: Int) -> KhovanovComplex<R> {
        .init(type, link, cube, chainComplex.shifted(shift), normalized)
    }
    
    public var degreeRange: ClosedRange<Int> {
        let (n, n⁺, n⁻) = (link.crossingNumber, link.crossingNumber⁺, link.crossingNumber⁻)
        return normalized ? (-n⁻ ... n⁺) : (0 ... n)
    }
    
    public var qDegreeRange: ClosedRange<Int> {
        let (qmin, qmax) = (cube.minQdegree, cube.maxQdegree)
        return qmin + qDegreeShift ... qmax + qDegreeShift
    }
    
    private var qDegreeShift: Int {
        let (n⁺, n⁻) = (link.crossingNumber⁺, link.crossingNumber⁻)
        return normalized ? n⁺ - 2 * n⁻ : 0
    }
    
    public func printSequence() {
        self.printSequence(degreeRange)
    }
    
    internal var asBigraded: ChainComplex2<BaseModule> {
        let (h, t) = (type.h, type.t)
        assert(h.isZero || h.degree == -2)
        assert(t.isZero || t.degree == -4)
        
        return chainComplex.asBigraded {
            summand in summand.generator.qDegree
        }.shifted(0, qDegreeShift)
    }
}

public struct KhovanovHomology<R: EuclideanRing>: ModuleGridType {
    public typealias BaseGrid = ModuleGrid2<KhovanovComplex<R>.BaseModule>
    public typealias BaseModule = BaseGrid.BaseModule
    public typealias Index  = BaseGrid.Index
    public typealias Object = BaseGrid.Object
    
    public let grid: BaseGrid
    public let chainComplex: KhovanovComplex<R>
    
    private init(_ grid: BaseGrid, _ chainComplex: KhovanovComplex<R>) {
        self.grid = grid
        self.chainComplex = chainComplex
    }

    public init (_ L: Link, normalized: Bool = true, options: HomologyCalculatorOptions = []) {
        let C = KhovanovComplex<R>(link: L, normalized: normalized)
        let H = C.asBigraded.homology(options: options)
        self.init(H, C)
    }
    
    public subscript(i: Index) -> BaseGrid.Object {
        grid[i]
    }

    public func shifted(_ shift: Index) -> Self {
        .init(grid.shifted(shift), chainComplex)
    }
    
    // Σ_{i, j} (-1)^i q^j rank(H[i, j])
    public var gradedEulerCharacteristic: LaurentPolynomial<𝐙, _q> {
        let (r1, r2) = (chainComplex.degreeRange, chainComplex.qDegreeRange)

        typealias P = LaurentPolynomial<𝐙, _q>
        let q = P.indeterminate

        return (r1 * r2).sum { (i, j) -> P in
            P((-1).pow(i) * self[i, j].rank) * q.pow(j)
        }
    }
    
    public func printTable() {
        let (r1, r2) = (chainComplex.degreeRange, chainComplex.qDegreeRange)
        let qMin = r2.lowerBound
        grid.printTable(r1, r2.filter{ j in (j - qMin).isEven})
    }
}
