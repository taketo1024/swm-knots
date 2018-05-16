//
//  Array.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/11/07.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public extension Array {
    public func binarySearch<T: Comparable>(_ needle: T, _ compare: (Element) -> T) -> (index: Int, element: Element)? {
        var l = 0
        var u = self.count - 1
        
        while l <= u {
            let i = (l + u) / 2
            let a = self[i]
            let x = compare(a)
            
            if(needle == x) {
                return (i, a)
            } else {
                if (needle < x) {
                    u = i - 1
                } else {
                    l = i + 1
                }
            }
        }
        return nil
    }
    
    public func dropLast(while predicate: (Element) throws -> Bool) rethrows -> ArraySlice<Element> {
        let rev = self.reversed().enumerated()
        for (i, a) in rev {
            let p: Bool
            do {
                p = try predicate(a)
            } catch let e {
                throw e
            }
            if !p {
                return i == 0 ? ArraySlice(self) : self[0 ..< count - i]
            }
        }
        return ArraySlice([])
    }
    
    public func appended(_ e: Element) -> [Element] {
        var a = self
        a.append(e)
        return a
    }
    
    public func replaced(at i: Int, with e: Element) -> [Element] {
        var a = self
        a[i] = e
        return a
    }
}

public extension Array where Element: Equatable {
    @discardableResult
    public mutating func remove(element: Element) -> Bool {
        if let i = index(of: element) {
            remove(at: i)
            return true
        } else {
            return false
        }
    }
}

extension Array: Comparable where Element: Comparable {
    public static func < (lhs: [Element], rhs: [Element]) -> Bool {
        return lhs.lexicographicallyPrecedes(rhs)
    }
    
    public func binarySearch(_ needle: Element) -> Int? {
        return binarySearch(needle, { $0 }).map{ $0.index }
    }
}

public extension Array where Element: Hashable {
    public func indexer() -> (Element) -> Int {
        return Dictionary(pairs: self.enumerated().map{ ($1, $0) }).asFunc()
    }
}
