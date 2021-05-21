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
        elements.isEmpty ?
            "0" :
            elements.map { (index, x) in
                "{\(index): \(x)}"
            }.joined(separator: " + ")
    }
}

extension ModuleStructure {
    public static func formDirectSum<Index: Hashable>(_ objects: [Index : Self]) -> ModuleStructure<IndexedModule<Index, BaseModule>> {
        let indices = objects.keys.toArray()
        let ranks = [0] + indices.map { objects[$0]!.rank }.accumulate()
        let shifts = Dictionary(zip(indices, ranks))
        
        let generators = indices.flatMap { index -> [IndexedModule<Index, BaseModule>] in
            objects[index]!.generators.map { x in IndexedModule(index: index, value: x) }
        }
        
        let N = ranks.last ?? 0
        let vectorizer = { (z: IndexedModule<Index, BaseModule>) -> AnySizeVector<R> in
            .init(size: N) { setEntry in
                z.elements.forEach { (index, x) in
                    let vec = objects[index]!.vectorize(x)
                    let shift = shifts[index]!
                    vec.nonZeroEntries.forEach{ (i, _, r) in
                        setEntry(i + shift, r)
                    }
                }
            }
        }
        
        return ModuleStructure<IndexedModule<Index, BaseModule>>(generators: generators, vectorizer: vectorizer)
    }
}
