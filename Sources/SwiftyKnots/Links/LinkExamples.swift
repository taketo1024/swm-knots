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
    public static var HopfLink: Link {
        return Link(name: "L2a1", planarCode: (4,1,3,2), (2,3,1,4))
    }
    public static var trefoil: Link {
        return Link(name: "3₁", planarCode: (1,4,2,5), (3,6,4,1), (5,2,6,3))
    }
}

