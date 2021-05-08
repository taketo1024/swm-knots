//
//  File.swift
//  
//
//  Created by Taketo Sano on 2021/05/07.
//

import SwiftyMath
import SwiftyHomology

// {M}_I: the direct sum of copies of M over I.
public struct IndexedModule<Index: Hashable, M: Module>: Module {
    public typealias BaseRing = M.BaseRing
    public let elements: [Index: M]
    
    public init(elements: [Index: M]) {
        self.elements = elements.exclude{ $0.value.isZero }
    }
    
    public init(index: Index, value: M) {
        self.init(elements: [index : value])
    }
    
    public static var zero: Self {
        self.init(elements: [:])
    }
    
    public static func + (a: Self, b: Self) -> Self {
        Self(elements: a.elements.merging(b.elements, uniquingKeysWith: +))
    }
    
    public static prefix func - (x: Self) -> Self {
        Self(elements: x.elements.mapValues{ -$0 })
    }
    
    public static func * (r: BaseRing, m: Self) -> Self {
        Self(elements: m.elements.mapValues{ r * $0 })
    }
    
    public static func * (m: Self, r: BaseRing) -> Self {
        Self(elements: m.elements.mapValues{ $0 * r })
    }
    
    public var description: String {
        elements.map { (index, x) in
            "{\(index): \(x)}"
        }.joined(separator: " + ")
    }
}

extension ModuleObject {
    public static func formDirectSum<Index: Hashable>(_ objects: [Index : Self]) -> ModuleObject<IndexedModule<Index, BaseModule>> {
        let indices = objects.keys.toArray()
        let ranks = [0] + indices.map { objects[$0]!.rank }.accumulate()
        let shifts = Dictionary(pairs: zip(indices, ranks))
        
        let generators = indices.flatMap { index -> [IndexedModule<Index, BaseModule>] in
            objects[index]!.generators.map { x in IndexedModule(index: index, value: x) }
        }
        
        let N = ranks.last ?? 0
        let vectorizer = { (z: IndexedModule<Index, BaseModule>) -> DVector<R> in
            let comps = z.elements.flatMap { (index, x) -> [MatrixComponent<R>] in
                let vec = objects[index]!.vectorize(x)
                let shift = shifts[index]!
                return vec.nonZeroComponents.map{ (i, _, r) in
                    (i + shift, 0, r)
                }
            }
            return DVector(size: (N, 1), components: comps)
        }
        
        return ModuleObject<IndexedModule<Index, BaseModule>>(basis: generators, vectorizer: vectorizer)
    }
}

extension Array where Element: AdditiveGroup {
    public func accumulate() -> Self {
        self.reduce(into: []) { (res, r) in
            res.append( (res.last ?? .zero) + r)
        }
    }
}
