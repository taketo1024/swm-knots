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
    
    public func torsionPart<t: _Int>(order: t.Type) -> SimpleModuleStructure<A, IntegerQuotientRing<t>> {
        typealias Q = IntegerQuotientRing<t>
        typealias Summand = SimpleModuleStructure<A, Q>.Summand
        
        let n = t.intValue
        let indices = (0 ..< self.summands.count).filter{ i in self[i].divisor == n }
        let sub = subSummands(indices: indices)
        
        let summands = sub.summands.map { s -> Summand in
            Summand(s.generator.mapValues{ Q($0) }, .zero)
        }
        let transform = sub.transform.mapValues { Q($0) }
        
        return SimpleModuleStructure<A, Q>(summands, basis, transform)
    }
    
    public var order2torsionPart: SimpleModuleStructure<A, 𝐙₂> {
        return torsionPart(order: _2.self)
    }
}

public extension SimpleModuleStructure where R == 𝐙₂ {
    public var asIntegerQuotients: SimpleModuleStructure<A, 𝐙> {
        typealias Summand = SimpleModuleStructure<A, 𝐙>.Summand
        let summands = self.summands.map { s -> Summand in
            Summand(s.generator.mapValues{ $0.representative }, 2)
        }
        let T = self.transform.mapValues{ a in a.representative }
        return SimpleModuleStructure<A, 𝐙>(summands, basis, T)
    }
}
