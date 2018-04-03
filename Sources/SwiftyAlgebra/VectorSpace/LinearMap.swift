//
//  LinearMap.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2018/04/02.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public protocol LinearMapType: ModuleHomType, VectorSpace where Domain: VectorSpace, Codomain: VectorSpace { }

public extension LinearMapType where Domain: FiniteDimVectorSpace, Codomain: FiniteDimVectorSpace {
    public init(matrix: DynamicMatrix<CoeffRing>) {
        self.init{ v in
            let x = DynamicVector(dim: Domain.dim, grid: v.standardCoordinates)
            let y = matrix * x
            return zip(y.grid, Codomain.standardBasis).sum { (a, w) in a * w }
        }
    }
    
    public var asMatrix: DynamicMatrix<CoeffRing> {
        let comps = Domain.standardBasis.enumerated().flatMap { (j, v) -> [MatrixComponent<CoeffRing>] in
            let w = self.applied(to: v)
            return w.standardCoordinates.enumerated().map { (i, a) in (i, j, a) }
        }
        return DynamicMatrix(rows: Codomain.dim, cols: Domain.dim, components: comps)
    }
    
    public var trace: CoeffRing {
        return asMatrix.trace
    }
    
    public var determinant: CoeffRing {
        return asMatrix.determinant
    }
}

public typealias LinearMap<Domain: VectorSpace, Codomain: VectorSpace> = ModuleHom<Domain, Codomain> where Domain.CoeffRing == Codomain.CoeffRing
extension LinearMap: VectorSpace, LinearMapType where Domain: VectorSpace, Codomain: VectorSpace, Domain.CoeffRing == Codomain.CoeffRing { }

public protocol LinearEndType: LinearMapType, EndType, LieAlgebra {}

public extension LinearEndType {
    public func bracket(_ g: Self) -> Self {
        let f = self
        return f ∘ g - g ∘ f
    }
}

public typealias LinearEnd<Domain: VectorSpace> = LinearMap<Domain, Domain>
extension Map: LinearEndType, LieAlgebra where Domain == Codomain, Domain: VectorSpace { }

public protocol LinearAutType: AutType where Domain: VectorSpace { }

public typealias LinearAut<Domain: VectorSpace> = Aut<Domain>
extension LinearAut: LinearAutType where Domain: VectorSpace { }
