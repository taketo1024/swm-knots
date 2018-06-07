//
//  LinkSpliceState.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public extension Link {
    
    /*
     *     \ /     0     \ /
     *      /     ===>   | |
     *     / \           / \
     *
     *
     *     \ /     1     \_/
     *      /     ===>
     *     / \           /‾\
     */

    @discardableResult
    public mutating func splice(at i: Int, type: Int) -> Link {
        switch type {
        case 0: crossings[i].splice0()
        case 1: crossings[i].splice1()
        default: fatalError()
        }
        return self
    }
    
    public func spliced(at i: Int, type: Int) -> Link {
        var L = self.copy(name: "\(name)\(Format.sub(type.description))")
        return L.splice(at: i, type: type)
    }

    public func spliced(by state: [Int]) -> Link {
        var L = self.copy()
        for (i, s) in state.enumerated() {
            L.splice(at: i, type: s)
        }
        return L
    }
    
    public func spliced(by state: IntList) -> Link {
        return spliced(by: state.components)
    }
    
    public func splicedPair(at i: Int) -> (Link, Link) {
        return (self.spliced(at: i, type: 0), self.spliced(at: i, type: 1))
    }
    
    public var allStates: [IntList] {
        return IntList.binaryCombinations(length: crossingNumber)
    }
}
