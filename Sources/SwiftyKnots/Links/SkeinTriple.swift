//
//  SkeinTriple.swift
//  Sample
//
//  Created by Taketo Sano on 2018/05/25.
//

import Foundation

public struct SkeinTriple {
    public let L: Link
    public let L0: Link
    public let L1: Link
    
    public init(_ L: Link, crossing: Int? = nil) {
        let n = L.crossingNumber
        let i = crossing ?? n - 1
        
        self.L = (i == n - 1) ? L : Link(name: L.name, crossings: L.crossings.moved(elementAt: i, to: n - 1))
        (self.L0, self.L1) = self.L.splicedPair(at: n - 1)
    }
}

public extension Link {
    public func skeinTriple(crossing: Int? = nil) -> SkeinTriple {
        return SkeinTriple(self, crossing: crossing)
    }
}
