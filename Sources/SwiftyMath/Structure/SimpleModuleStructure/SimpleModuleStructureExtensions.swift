//
//  SimpleModuleStructureExtensions.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/05/22.
//

import Foundation

// EuclideanRing extensions

// Int Extensions

public extension SimpleModuleStructure where R == 𝐙 {
    public var structure: [Int : Int] {
        return summands.group{ $0.divisor }.mapValues{ $0.count }
    }
    
    public var structureCode: String {
        return structure.sorted{ $0.key }.map { (d, r) in
            "\(r)\(d == 0 ? "" : Format.sub(d))"
        }.joined()
    }
    
    public func orderNtorsionPart<n: _Int>(_ type: n.Type) -> SimpleModuleStructure<A, IntegerQuotientRing<n>> {
        typealias Q = IntegerQuotientRing<n>
        typealias Summand = SimpleModuleStructure<A, Q>.Summand
        
        let n = n.intValue
        let indices = (0 ..< self.summands.count).filter{ i in self[i].divisor == n }
        let sub = subSummands(indices: indices)
        
        let summands = sub.summands.map { s -> Summand in
            Summand(s.generator.mapValues{ Q($0) }, .zero)
        }
        let transform = sub.transform.mapValues { Q($0) }
        
        return SimpleModuleStructure<A, Q>(summands, basis, transform)
    }
    
    public var order2torsionPart: SimpleModuleStructure<A, 𝐙₂> {
        return orderNtorsionPart(_2.self)
    }
}
