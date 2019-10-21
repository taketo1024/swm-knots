//
//  RasmussenInvariant.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/05/31.
//

import SwiftyMath
import SwiftyHomology

extension FreeModuleType {
    func filter(_ predicate: (Generator, BaseRing) -> Bool) -> Self {
        .init(elements: elements.filter(predicate))
    }
}

extension ModuleObject where BaseModule: FreeModuleType {
    func filter(_ f: @escaping (BaseModule.Generator) -> Bool) -> ModuleObject {
        let basis = generators.compactMap { z -> BaseModule.Generator? in
            assert(z.isGenerator)
            let a = z.unwrap()!
            return f(a) ? a : nil
        }
        return ModuleObject(basis: basis)
    }
}

extension ModuleHom where X: FreeModuleType, Y: FreeModuleType {
    public func asMatrix(from: ModuleObject<X>,to: ModuleObject<Y>) -> DMatrix<BaseRing> {
        DMatrix(size: (to.generators.count, from.generators.count)) { setEntry in
            from.generators.enumerated().forEach { (j, z) in
                let w = self.applied(to: z)
                to.factorize(w).nonZeroComponents.forEach{ (i, _, a) in
                    setEntry(i, j, a)
                }
            }
        }
    }
}

public func RasmussenInvariant(_ L: Link) -> Int {
    RasmussenInvariant(L, 𝐐.self)
}

public func RasmussenInvariant<F: Field>(_ L: Link, _ type: F.Type) -> Int {
    if L.components.count == 0 {
        return 0
    }
    
    let (n⁺, n⁻) = (L.crossingNumber⁺, L.crossingNumber⁻)
    let qShift = n⁺ - 2 * n⁻
    
    let C = KhovanovComplex<F>(type: .Lee, link: L)
    let z = C.LeeCycle(L)
    let d = C.differential(at: -1)
    
    let range = C[0].generators.map{ $0.degree }.range!
    let min = range.lowerBound
    
    for j in range where (j - min).isEven {
        let FC0 = C[ 0].filter{ x in x.degree < j }
        let FC1 = C[-1].filter{ x in x.degree < j }
        
        let A = d.asMatrix(from: FC1, to: FC0)
        let b = FC0.factorize(z)
        
        let E = MatrixEliminator.eliminate(target: A, form: .Diagonal)
        if let x = E.invert(b) {
            assert(A * x == b)
        } else {
            return j + qShift - 1
        }
    }
    
    fatalError()
}
