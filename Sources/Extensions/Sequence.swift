//
//  Sequence.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/19.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

internal extension Sequence {
    func forAll(_ f: (Iterator.Element) -> Bool) -> Bool {
        for e in self {
            if !f(e) {
                return false
            }
        }
        return true
    }
    
    func exists(_ f: (Iterator.Element) -> Bool) -> Bool {
        for e in self {
            if f(e) {
                return true
            }
        }
        return false
    }
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var alreadyAdded = Set<Iterator.Element>()
        return self.filter { alreadyAdded.insert($0).inserted }
    }
}

extension Sequence {
    func group<U: Hashable>(by keyGenerator: (Iterator.Element) -> U) -> [U: [Iterator.Element]] {
        var groups: [U: Ref<[Iterator.Element]>] = [:]
        for element in self {
            let key = keyGenerator(element)
            if case nil = groups[key]?.value.append(element) {
                groups[key] = Ref([element])
            }
        }
        var result: [U: [Iterator.Element]] = Dictionary(minimumCapacity: groups.count)
        for (key,valRef) in groups {
            result[key] = valRef.value
        }
        return result
    }
}
