//
//  KhComplex.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/10/10.
//

import SwiftyMath
import SwiftyHomology

public struct KhovanovComplex<R: Ring>: ChainComplexWrapper {
    public typealias GridDim = _1
    public typealias BaseModule = IndexedModule<Cube.Coords, LinearCombination<MultiTensorGenerator<KhovanovAlgebraGenerator>, R>>
    
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
    
    public func shifted(_ shift: GridCoords<_1>) -> KhovanovComplex<R> {
        .init(type, link, cube, chainComplex.shifted(shift), normalized)
    }
    
    public var bigraded: ChainComplex2<BaseModule> {
        let (h, t) = (type.h, type.t)
        assert(h.isZero || h.degree == -2)
        assert(t.isZero || t.degree == -4)
        
        let (n⁺, n⁻) = (link.crossingNumber⁺, link.crossingNumber⁻)
        let (qmin, qmax) = (cube.minQdegree, cube.maxQdegree)
        
        return chainComplex.asBigraded(secondarySupport: qmin ... qmax) {
            summand in summand.generator.qDegree
        }.shifted(0, normalized ? n⁺ - 2 * n⁻ : 0)
    }
}

public struct KhovanovHomology<R: HomologyComputable>: GridWrapper {
    public typealias Grid = ModuleGrid2<KhovanovComplex<R>.BaseModule>
    public typealias GridDim = _2
    public typealias Object = Grid.Object
    
    public let grid: Grid
    
    private init(_ grid: Grid) {
        self.grid = grid
    }

    public init (_ L: Link, normalized: Bool = true, options: HomologyCalculatorOptions = []) {
        let C = KhovanovComplex<R>(link: L, normalized: normalized)
        let H = C.bigraded.homology(options: options)
        self.init(H)
    }

    public func shifted(_ shift: Coords) -> Self {
        .init(grid.shifted(shift))
    }
    
    // Σ_{i, j} (-1)^i q^j rank(H[i, j])
    public var gradedEulerCharacteristic: LaurentPolynomial<_q, 𝐙> {
        guard let support = support else { return .zero }
        let (r1, r2) = support.range
        
        typealias P = LaurentPolynomial<_q, 𝐙>
        let q = P.indeterminate
        
        return (r1 * r2).sum { (i, j) -> P in
            P((-1).pow(i) * self[i, j].rank) * q.pow(j)
        }
    }
    
    public func printTable() {
        guard let support = support else { return }
        let (r0, r1) = support.range
        let qMin = r1.min() ?? 0
        grid.printTable(r0, r1.filter{ j in (j - qMin).isEven})
    }
}
