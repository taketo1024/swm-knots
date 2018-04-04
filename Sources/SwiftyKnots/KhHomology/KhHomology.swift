//
//  KhHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath

public typealias KhHomology<R: EuclideanRing> = Cohomology<KhTensorElement, R>
public extension KhHomology where T == Ascending, A == KhTensorElement, R: EuclideanRing {
    public convenience init(_ L: Link, _ type: R.Type) {
        let name = "Kh(\(L.name); \(R.symbol))"
        let C = KhChainComplex(L, R.self)
        self.init(name: name, chainComplex: C)
    }
}
