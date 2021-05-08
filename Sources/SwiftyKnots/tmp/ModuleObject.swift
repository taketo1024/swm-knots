//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/07.
//

import SwiftyMath
import SwiftyHomology

extension ModuleObject {
    public func filter(_ predicate: @escaping (BaseModule) -> Bool) -> ModuleObject {
        assert(isFree)
        
        let (reduced, map) = generators.enumerated().reduce(into: ([], [:])) { (res: inout ([BaseModule], [Int : Int]), next) in
            let (i, z) = next
            if predicate(z) {
                let j = res.0.count
                res.0.append(z)
                res.1[i] = j
            }
        }
        
        let N = reduced.count
        let vectorizer = { (z: BaseModule) -> DVector<R> in
            let vec = vectorize(z)
            let comps = vec.nonZeroComponents.compactMap{ (i, _, r) -> MatrixComponent<R>? in
                if let j = map[i]  {
                    return (j, 0, r)
                } else {
                    return nil
                }
            }
            return DVector(size: (N, 1), components: comps)
        }
        
        return ModuleObject(basis: reduced, vectorizer: vectorizer)
    }
}

extension ChainComplex1 where GridDim == _1 {
    public func asBigraded(secondarySupport: ClosedRange<Int>? = nil, differentialSecondaryDegree: Int = 0, secondaryDegreeMap: @escaping (BaseModule) -> Int) -> ChainComplex2<BaseModule> {
        let support = { () -> ClosedRange<GridCoords<_2>>? in
            if let s1 = self.support, let s2 = secondarySupport {
                return [s1.lowerBound[0], s2.lowerBound] ... [s1.upperBound[0], s2.upperBound]
            } else {
                return nil
            }
        }()
        
        return ChainComplex2(
            support: support,
            differentialDegree: [differential.degree, differentialSecondaryDegree],
            grid: { I in
                let (i, j) = (I[0], I[1])
                return self[i].filter { z in secondaryDegreeMap(z) == j }
            },
            differential: { I in self.differential[I[0]] }
        )
    }
}
