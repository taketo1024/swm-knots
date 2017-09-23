//
//  Sequence.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/19.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

internal extension Sequence {
    func forAll(_ f: (Element) -> Bool) -> Bool {
        for e in self {
            if !f(e) {
                return false
            }
        }
        return true
    }
    
    func exists(_ f: (Element) -> Bool) -> Bool {
        for e in self {
            if f(e) {
                return true
            }
        }
        return false
    }
}

extension Sequence where Element: Hashable {
    func unique() -> [Element] {
        var alreadyAdded = Set<Element>()
        return self.filter { alreadyAdded.insert($0).inserted }
    }
    
    func subtract(_ b: Self) -> [Element] {
        let set = Set(b)
        return self.filter{ !set.contains($0) }
    }
}

extension Sequence {
    func group<U: Hashable>(by keyGenerator: (Element) -> U) -> [U: [Element]] {
        return Dictionary(grouping: self, by: keyGenerator)
    }
    
    func allCombinations<S: Sequence>(with s2: S) -> [(Self.Element, S.Element)] {
        typealias X = Self.Element
        typealias Y = S.Element
        return self.flatMap{ (x) -> [(X, Y)] in
            s2.map{ (y) -> (X, Y) in (x, y) }
        }
    }
    
    // TODO remove
    func groupMap<U: Hashable, T>(by generator: (Element) -> (key: U, value: T)) -> [U: [T]] {
        var groups: [U: Ref<[T]>] = [:]
        for element in self {
            let (key, val) = generator(element)
            if case nil = groups[key]?.value.append(val) {
                groups[key] = Ref([val])
            }
        }
        var result: [U: [T]] = Dictionary(minimumCapacity: groups.count)
        for (key,valRef) in groups {
            result[key] = valRef.value
        }
        return result
    }
}
