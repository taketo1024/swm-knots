//
//  LinkExamples.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import SwiftyMath

// see:
// - Knot Table  http://katlas.org/wiki/The_Rolfsen_Knot_Table
// - Link Table  http://katlas.org/wiki/The_Thistlethwaite_Link_Table
// - Torus Knots http://katlas.org/wiki/36_Torus_Knots

public func Knot(_ n: Int, _ i: Int) -> Link {
    assert( (3...10).contains(n) )
    let name = "\(n)_\(i)"
    return Link.load(name)
}

extension Link {
    public enum LinkType {
        case knot, link
    }
    
    public static var empty: Link {
        Link(name: "∅", crossings: [])
    }
    
    public static var unknot: Link {
        var L = Link(name: "○", planarCode: [1, 2, 2, 1])
        L.resolve(0, .resolution0)
        return L
    }
    
    public static var trefoil: Link {
        Link.load("3_1")
    }
    
    public static var HopfLink: Link {
        Link.load("L2a1")
    }
}
