//
//  RasmussenInvariant.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/05/31.
//

import SwiftyMath
import SwiftyHomology

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
    let z = C.canonicalCycles.0
    let d = C.differential[-1]
    
    let range = C[0].generators.map{ $0.unwrap()!.quantumDegree }.range!
    let min = range.lowerBound
    
    for j in range where (j - min).isEven {
        let FC0 = C[ 0].filter{ x in x.quantumDegree < j }
        let FC1 = C[-1].filter{ x in x.quantumDegree < j }
        
        let A = d.asMatrix(from: FC1, to: FC0)
        let b = FC0.vectorize(z)
        
        let E = MatrixEliminator.eliminate(target: A, form: .Diagonal)
        if let x = E.invert(b) {
            assert(A * x == b)
        } else {
            return j + qShift - 1
        }
    }
    
    fatalError()
}
