//
//  LinkExamples.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

// see:
// - Knot Table  http://katlas.org/wiki/The_Rolfsen_Knot_Table
// - Link Table  http://katlas.org/wiki/The_Thistlethwaite_Link_Table
// - Torus Knots http://katlas.org/wiki/36_Torus_Knots

public extension Link {
    public static func Rolfsen(_ i: Int, _ j: Int) -> Link {
        let name = "\(i)\(Format.sub(j))"
        let code = { () -> [(Int, Int, Int, Int)] in
            switch (i, j) {
            case (3, 1): return [(1,4,2,5), (3,6,4,1), (5,2,6,3)]
            case (4, 1): return [(4,2,5,1), (8,6,1,5), (6,3,7,4), (2,7,3,8)]
            case (5, 1): return [(1,6,2,7), (3,8,4,9), (5,10,6,1), (7,2,8,3), (9,4,10,5)]
            case (8, 8): return [(1,4,2,5), (3,8,4,9), (11,15,12,14), (5,13,6,12), (13,7,14,6), (9,1,10,16), (15,11,16,10), (7,2,8,3)]
            case (10, 129): return [(1,4,2,5), (3,8,4,9), (5,14,6,15), (20,16,1,15), (16,10,17,9), (10,20,11,19), (18,12,19,11), (12,18,13,17), (13,6,14,7), (7,2,8,3)]
            default: fatalError("Knot \(name) is not supported yet.")
            }
        }()
        
        return Link(name: name, planarCode: code)
    }
    
    public static var HopfLink: Link {
        return Link(name: "L2a1", planarCode: (4,1,3,2), (2,3,1,4))
    }
    
    public static var trefoil: Link {
        return Rolfsen(3, 1)
    }
}

